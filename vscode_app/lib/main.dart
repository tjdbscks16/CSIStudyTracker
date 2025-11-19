import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

// ✅ Firebase 초기화
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSI Study Tracker',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF3F4F8),
        primaryColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF1A1A2E),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// -------------------------------------------------------------------
// 메인 페이지
// -------------------------------------------------------------------

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    TimerPage(),
    RecordsPage(),
    StatsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            label: '타이머',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            label: '기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: '통계',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// -------------------------------------------------------------------
// -------------------------------------------------------------------


// -------------------------------------------------------------------
// 1️⃣ 타이머 페이지 (누적 시간 표시)
// -------------------------------------------------------------------

enum TimerStatus { stopped, recognizing, running }

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Timer? _uiUpdateTimer;
  final Stopwatch _stopwatch = Stopwatch();
  String _formattedTime = '00:00:00';
  TimerStatus _status = TimerStatus.stopped;

  StreamSubscription<DatabaseEvent>? _statusSubscription;
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref('/heatmap_predictions');

  bool _isStudyingDetected = false;
  bool _isManuallyPaused = false;

  DateTime? _lastStateChangeTime;
  String _currentLabel = 'vacant';

  // 오늘 누적 공부 시간
  int _todayAccumulatedSeconds = 0;
  bool _isLoadingTodayData = true;

  @override
  void initState() {
    super.initState();
    _loadTodayStudyTime();
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    _statusSubscription?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  // 오늘 공부 시간 로드
  Future<void> _loadTodayStudyTime() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final ref = FirebaseDatabase.instance.ref('/records/$today');

    try {
      final snapshot = await ref.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _todayAccumulatedSeconds = (data['study_time'] ?? 0) as int;
          _isLoadingTodayData = false;
        });
      } else {
        setState(() {
          _todayAccumulatedSeconds = 0;
          _isLoadingTodayData = false;
        });
      }
    } catch (e) {
      setState(() {
        _todayAccumulatedSeconds = 0;
        _isLoadingTodayData = false;
      });
    }

    _updateFormattedTime();
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  void _updateFormattedTime() {
    final currentSessionSeconds = _stopwatch.elapsed.inSeconds;
    final totalSeconds = _todayAccumulatedSeconds + currentSessionSeconds;
    final totalDuration = Duration(seconds: totalSeconds);
    setState(() {
      _formattedTime = _formatTime(totalDuration);
    });
  }

  void _startTimer() {
    setState(() {
      _status = TimerStatus.recognizing;
    });
    _startListeningToFirebase();
  }

  void _toggleManualPause() {
    setState(() {
      _isManuallyPaused = !_isManuallyPaused;
    });

    if (_isManuallyPaused) {
      _handleStateChange('vacant');
      _statusSubscription?.pause();
      setState(() => _isStudyingDetected = false);
    } else {
      _statusSubscription?.resume();
    }
  }

  void _stopAndReset() {
    _uiUpdateTimer?.cancel();
    _statusSubscription?.cancel();
    _stopwatch.stop();
    _stopwatch.reset();
    setState(() {
      _status = TimerStatus.stopped;
      _isStudyingDetected = false;
      _isManuallyPaused = false;
    });
    _updateFormattedTime();
  }

  void _startListeningToFirebase() {
    _statusSubscription?.cancel();

    _statusSubscription = _dbRef.orderByKey().limitToLast(1).onValue.listen(
      (DatabaseEvent event) {
        if (_status == TimerStatus.recognizing) {
          setState(() => _status = TimerStatus.running);
        }

        if (event.snapshot.value != null && !_isManuallyPaused) {
          try {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            final latestKey = data.keys.first;
            final latestPrediction = data[latestKey] as Map<dynamic, dynamic>;
            String predictedLabel =
                latestPrediction['predicted_label'] ?? 'vacant';
            _handleStateChange(predictedLabel);
          } catch (e) {
            _handleStateChange('vacant');
          }
        }
      },
      onError: (error) {
        _handleStateChange('vacant');
      },
    );
  }

  void _handleStateChange(String label) {
    if (label == _currentLabel) return;

    final now = DateTime.now();
    if (_lastStateChangeTime != null) {
      final duration = now.difference(_lastStateChangeTime!).inSeconds;

      if (_currentLabel == 'studying') {
        _saveRecord('study', duration);
        setState(() {
          _todayAccumulatedSeconds += duration;
        });
      } else if (_currentLabel == 'vacant' || _currentLabel == 'sleeping') {
        _saveRecord('break', duration);
      }
    }

    _currentLabel = label;
    _lastStateChangeTime = now;

    if (label == 'studying') {
      if (!_stopwatch.isRunning) {
        _stopwatch.start();
        _startTimerUIUpdate();
      } else if (_uiUpdateTimer == null || !_uiUpdateTimer!.isActive) {
        _startTimerUIUpdate();
      }
      setState(() => _isStudyingDetected = true);
    } else {
      if (_stopwatch.isRunning) _stopwatch.stop();
      setState(() => _isStudyingDetected = false);
    }
  }

  Future<void> _saveRecord(String type, int seconds) async {
    final date = DateTime.now().toIso8601String().split('T')[0];
    final ref = FirebaseDatabase.instance.ref('/records/$date');

    final snapshot = await ref.get();
    final existingData = snapshot.value as Map<dynamic, dynamic>? ?? {};

    int studyTime = (existingData['study_time'] ?? 0);
    int breakTime = (existingData['break_time'] ?? 0);

    if (type == 'study') {
      studyTime += seconds;
    } else if (type == 'break') {
      breakTime += seconds;
    }

    await ref.update({
      'study_time': studyTime,
      'break_time': breakTime,
    });
  }

  void _startTimerUIUpdate() {
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_stopwatch.isRunning) return;
      _updateFormattedTime();
    });
  }

  /// ✅ 상태 텍스트 함수 (sleeping 포함)
  String getStatusText() {
    if (_isManuallyPaused) return "일시정지됨";

    switch (_currentLabel) {
      case 'studying':
        return '공부 중 감지';
      case 'vacant':
        return '자리 이탈';
      case 'sleeping':
        return '자는 중';
      default:
        return '미감지';
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkColor = Color(0xFF1A1A2E);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWithDateTime(),
            Expanded(
              child: Center(
                child: _isLoadingTodayData
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTimerCircle(darkColor),
                          const SizedBox(height: 60),
                          _buildButtonArea(darkColor),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------
  // 원형 타이머 UI
  // ---------------------------------------
  Widget _buildTimerCircle(Color darkColor) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _status == TimerStatus.recognizing
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: darkColor, strokeWidth: 3),
                const SizedBox(height: 20),
                const Text('행동 인식 중...',
                    style: TextStyle(color: Colors.grey, fontSize: 18)),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('오늘 총 공부 시간',
                    style: TextStyle(color: Colors.grey, fontSize: 18)),
                const SizedBox(height: 10),
                Text(
                  _formattedTime,
                  style: TextStyle(
                      color: darkColor,
                      fontSize: 50,
                      fontWeight: FontWeight.bold),
                ),
                if (_status == TimerStatus.running) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _isStudyingDetected && !_isManuallyPaused
                              ? Colors.green
                              : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),

                      /// ✅ 이제 sleeping 포함하여 정상 표시됨
                      Text(
                        getStatusText(),
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  // ---------------------------------------
  // 버튼영역
  // ---------------------------------------
  Widget _buildButtonArea(Color darkColor) {
    if (_status == TimerStatus.stopped) {
      return ElevatedButton.icon(
        onPressed: _startTimer,
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: const Text('시작하기',
            style: TextStyle(fontSize: 18, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 18),
        ),
      );
    } else if (_status == TimerStatus.recognizing) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: const Text('시작하기',
            style: TextStyle(fontSize: 18, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 18),
        ),
      );
    } else {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: _toggleManualPause,
            icon: Icon(
              _isManuallyPaused ? Icons.play_arrow : Icons.pause,
              color: darkColor,
            ),
            label: Text(
              _isManuallyPaused ? '다시시작' : '일시정지',
              style: TextStyle(fontSize: 18, color: darkColor),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 80, vertical: 18),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _stopAndReset,
            icon: Icon(Icons.refresh, color: darkColor),
            label: Text(
              '초기화',
              style: TextStyle(fontSize: 18, color: darkColor),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 80, vertical: 18),
            ),
          ),
        ],
      );
    }
  }
}

// -------------------------------------------------------------------
// ✅ 상단 문구 + 날짜 + 시간 표시 위젯 (실시간 갱신)
// -------------------------------------------------------------------

class HeaderWithDateTime extends StatelessWidget {
  const HeaderWithDateTime({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SizedBox(height: 50),
        Text(
          "DO STUDY WITH TEMPO",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        SizedBox(height: 8),
        DateTimeDisplay(), // ✅ 실시간 갱신 시계
      ],
    );
  }
}

// -------------------------------------------------------------------
// 실시간 시계 위젯 (한국 시간대 수정)
// -------------------------------------------------------------------

class DateTimeDisplay extends StatefulWidget {
  const DateTimeDisplay({super.key});

  @override
  State<DateTimeDisplay> createState() => _DateTimeDisplayState();
}

class _DateTimeDisplayState extends State<DateTimeDisplay> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 명시적으로 로컬 시간 사용
     final localTime = _now.isUtc 
      ? _now.add(const Duration(hours: 9))
      : _now;
    
     final formattedDate =
      "${localTime.year}년 ${localTime.month.toString().padLeft(2, '0')}월 ${localTime.day.toString().padLeft(2, '0')}일";
     final formattedTime =
      "${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}:${localTime.second.toString().padLeft(2, '0')}";

    return Column(
      children: [
        Text(
          formattedDate,
          style: const TextStyle(fontSize: 17, color: Colors.grey),
        ),
        Text(
          formattedTime,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}
// -------------------------------------------------------------------
// 2️⃣ 기록 페이지 (평가 기능 추가)
// -------------------------------------------------------------------

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('/records');
  Map<String, dynamic>? todayData;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final snapshot = await _ref.child(today).get();
    if (snapshot.exists) {
      setState(() {
        todayData = Map<String, dynamic>.from(snapshot.value as Map);
      });
    }
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '$h시간 $m분 $s초';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final studyTime = todayData?['study_time'] ?? 0;
    final breakTime = todayData?['break_time'] ?? 0;

    // 휴식 비율 계산
    double breakPercentage = studyTime > 0 ? (breakTime / studyTime) * 100 : 0;
    
    // 평가 메시지 및 색상
    String evaluationMessage;
    Color evaluationColor;
    String emojiAsset;
    
    if (breakPercentage <= 30) {
      evaluationMessage = "훌륭해요! 집중력이 매우 높습니다 💪";
      evaluationColor = Colors.green;
      emojiAsset = 'assets/images/emoji_excellent.png';
    } else if (breakPercentage <= 60) {
      evaluationMessage = "준수해요! 좋은 학습 패턴입니다 👍";
      evaluationColor = Colors.orange;
      emojiAsset = 'assets/images/emoji_good.png';
    } else {
      evaluationMessage = "휴식 시간을 조금 줄여보는 건 어떨까요? 🤔";
      evaluationColor = Colors.red;
      emojiAsset = 'assets/images/emoji_warning.png';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("오늘의 공부 기록"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: todayData == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "오늘 하루 동안 집중한 시간을 확인하세요",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // 메인 카드
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "${today.year}년 ${today.month}월 ${today.day}일",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "오늘 집중 공부",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            const Divider(height: 30),
                            
                            // 공부 시간
                            Text("총 공부 시간",
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(
                              _formatDuration(studyTime),
                              style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            ),
                            const SizedBox(height: 20),
                            
                            // 휴식 시간
                            Text("휴식 시간",
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(
                              _formatDuration(breakTime),
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 평가 카드
                    if (studyTime > 0)
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        color: const Color(0xFFF8F3E7),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: evaluationColor.withOpacity(0.3),
                                width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              // 오늘의 집중도 (이모티콘 제거)
                              Text(
                                "오늘의 집중도",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: evaluationColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // 휴식 비율 표시
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "휴식 비율: ${breakPercentage.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: evaluationColor,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // 평가 메시지
                              Text(
                                evaluationMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: evaluationColor.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // 큰 이모티콘
                              Image.asset(
                                emojiAsset,
                                width: 150,
                                height: 150,
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // 데이터가 없을 때 안내
                    if (studyTime == 0)
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                "아직 오늘의 공부 기록이 없습니다",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "타이머를 시작해서 공부를 기록해보세요!",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
// -------------------------------------------------------------------
// 3️⃣ 통계 페이지 (Placeholder)
// -------------------------------------------------------------------

// -------------------------------------------------------------------
// 3️⃣ 통계 페이지 (라이브러리 없는 버전)
// -------------------------------------------------------------------

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('/records');
  Map<String, dynamic> allData = {};
  bool isLoading = true;
  bool showWeekly = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final snapshot = await _ref.get();
    if (snapshot.exists) {
      setState(() {
        allData = Map<String, dynamic>.from(snapshot.value as Map);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getWeekdayKorean(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[date.weekday - 1];
  }

  // 오늘 공부시간 계산
  int getTodayStudyMinutes() {
    final today = _formatDate(DateTime.now());
    final data = allData[today];
    if (data == null) return 0;
    return ((data['study_time'] ?? 0) / 60).round();
  }

  // 이번주 공부시간 계산
  int getWeekStudyMinutes() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    int total = 0;
    for (int i = 0; i < 7; i++) {
      String dateKey = _formatDate(startOfWeek.add(Duration(days: i)));
      final data = allData[dateKey];
      if (data != null && data['study_time'] != null) {
        total += ((data['study_time'] as num) / 60).round();
      }
    }
    return total;
  }

  // 이번달 공부시간 계산
  int getMonthStudyMinutes() {
    final now = DateTime.now();
    int total = 0;
    allData.forEach((key, value) {
      try {
        DateTime d = DateTime.parse(key);
        if (d.year == now.year && d.month == now.month) {
          if (value['study_time'] != null) {
            total += ((value['study_time'] as num) / 60).round();
          }
        }
      } catch (e) {
        // 날짜 파싱 에러 무시
      }
    });
    return total;
  }

  // 주간 데이터
  List<Map<String, dynamic>> getWeeklyData() {
    DateTime now = DateTime.now();
    List<Map<String, dynamic>> list = [];
    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      String key = _formatDate(day);
      final data = allData[key] ?? {'study_time': 0, 'break_time': 0};
      list.add({
        'date': day,
        'dateStr': key,
        'study': (data['study_time'] ?? 0) / 3600.0,
        'break': (data['break_time'] ?? 0) / 3600.0,
      });
    }
    return list;
  }

  // 월별 데이터
  Map<int, double> getMonthlyData() {
    Map<int, double> monthly = {};
    allData.forEach((key, value) {
      try {
        DateTime d = DateTime.parse(key);
        int m = d.month;
        double currentValue = monthly[m] ?? 0;
        if (value['study_time'] != null) {
          currentValue += (value['study_time'] as num) / 3600.0;
        }
        monthly[m] = currentValue;
      } catch (e) {
        // 날짜 파싱 에러 무시
      }
    });
    return monthly;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final today = getTodayStudyMinutes();
    final week = getWeekStudyMinutes();
    final month = getMonthStudyMinutes();
    final weeklyData = getWeeklyData();
    final monthlyData = getMonthlyData();

    return Scaffold(
      appBar: AppBar(
        title: const Text("공부 시간 통계"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 상단 카드 3개
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryCard(Icons.calendar_today, "오늘", "$today분", Colors.blue.shade50),
                _buildSummaryCard(Icons.show_chart, "이번 주", "$week분", Colors.green.shade50),
                _buildSummaryCard(Icons.bar_chart, "이번 달", "$month분", Colors.purple.shade50),
              ],
            ),
            const SizedBox(height: 20),

            // 주간 / 월간 전환 탭
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTabButton("주간", showWeekly),
                  _buildTabButton("월간", !showWeekly),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 주간 그래프 or 월간 리스트
            showWeekly
                ? _buildWeeklyChart(weeklyData)
                : _buildMonthlyList(monthlyData),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(IconData icon, String title, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1A1A2E)),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            showWeekly = label == "주간";
          });
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(List<Map<String, dynamic>> data) {
    double maxHours = 0;
    double totalStudy = 0;
    double totalBreak = 0;
    
    for (var d in data) {
      double study = d['study'];
      double breakTime = d['break'];
      totalStudy += study;
      totalBreak += breakTime;
      double total = study + breakTime;
      if (total > maxHours) maxHours = total;
    }
    if (maxHours == 0) maxHours = 1;

    // 휴식 비율 계산
    double breakPercentage = totalStudy > 0 ? (totalBreak / totalStudy) * 100 : 0;
    
    // 평가 메시지 및 색상
    String evaluationMessage;
    Color evaluationColor;
    IconData evaluationIcon;
    
    if (breakPercentage <= 30) {
      evaluationMessage = "훌륭해요! 이번 주 집중력이 매우 높습니다 💪";
      evaluationColor = Colors.green;
      evaluationIcon = Icons.sentiment_very_satisfied;
    } else if (breakPercentage <= 60) {
      evaluationMessage = "준수해요! 이번 주 좋은 학습 패턴입니다 👍";
      evaluationColor = Colors.orange;
      evaluationIcon = Icons.sentiment_satisfied;
    } else {
      evaluationMessage = "휴식 시간을 조금 줄여보는 건 어떨까요? 🤔";
      evaluationColor = Colors.red;
      evaluationIcon = Icons.sentiment_dissatisfied;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "최근 7일간 공부 시간",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            // 간단한 막대 그래프
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: data.map((d) {
                  DateTime date = d['date'];
                  double studyHours = d['study'];
                  double breakHours = d['break'];
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 시간 표시
                          if (studyHours + breakHours > 0)
                            Text(
                              '${(studyHours + breakHours).toStringAsFixed(1)}h',
                              style: const TextStyle(fontSize: 10),
                            ),
                          const SizedBox(height: 4),
                          
                          // 막대 그래프
                          Container(
                            width: double.infinity,
                            height: (studyHours / maxHours) * 150,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          if (breakHours > 0)
                            Container(
                              width: double.infinity,
                              height: (breakHours / maxHours) * 150,
                              decoration: BoxDecoration(
                                color: Colors.green.shade300,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                          
                          const SizedBox(height: 4),
                          // 요일 표시
                          Text(
                            _getWeekdayKorean(date),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.square, color: Colors.blue, size: 12),
                SizedBox(width: 4),
                Text("공부시간", style: TextStyle(fontSize: 12)),
                SizedBox(width: 10),
                Icon(Icons.square, color: Colors.green, size: 12),
                SizedBox(width: 4),
                Text("휴식시간", style: TextStyle(fontSize: 12)),
              ],
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            
            // 주간 총합 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      "총 공부시간",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${totalStudy.toStringAsFixed(1)}시간",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                Column(
                  children: [
                    const Text(
                      "총 휴식시간",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${totalBreak.toStringAsFixed(1)}시간",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 휴식 비율 표시
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: evaluationColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: evaluationColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(evaluationIcon, color: evaluationColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "휴식 비율: ${breakPercentage.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: evaluationColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          evaluationMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: evaluationColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyList(Map<int, double> monthlyData) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "월별 공부 시간",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ...List.generate(12, (i) {
              int month = i + 1;
              double hours = monthlyData[month] ?? 0;
              return ListTile(
                dense: true,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hours > 0 ? Colors.purple.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "$month월",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hours > 0 ? Colors.purple : Colors.grey,
                    ),
                  ),
                ),
                title: hours == 0
                    ? const Text("-", style: TextStyle(color: Colors.grey))
                    : Text(
                        "${hours.toStringAsFixed(1)}시간",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }
}