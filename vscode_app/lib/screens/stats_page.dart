import 'package:flutter/material.dart';
import 'package:vscode_app/widgets/summary_card.dart'; // 요약 카드 위젯
import 'package:vscode_app/widgets/study_duration_bar.dart'; // 공부 시간 바 위젯

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _selectedPeriod = 0; // 0: 주간, 1: 월간

  @override
  Widget build(BuildContext context) {
    const Color darkColor = Color(0xFF1A1A2E); // 주 색상 (네이비)
    const Color lightGreyColor = Color(0xFFF3F4F8); // 배경색

    // 예시 데이터 (실제 데이터는 Firebase 등에서 가져옴)
    final List<Map<String, dynamic>> weeklyData = [
      {'date': '10월 30일', 'duration': 0},
      {'date': '10월 31일', 'duration': 0},
      {'date': '11월 1일', 'duration': 0},
      {'date': '11월 2일', 'duration': 0},
      {'date': '11월 3일', 'duration': 0},
      {'date': '11월 4일', 'duration': 0},
      {'date': '11월 5일', 'duration': 4}, // 4분
    ];

    final List<Map<String, dynamic>> monthlyData = [
      {'date': '10월 7일', 'duration': 0},
      {'date': '10월 8일', 'duration': 0},
      {'date': '10월 9일', 'duration': 0},
      {'date': '10월 10일', 'duration': 0},
      {'date': '10월 11일', 'duration': 0},
      {'date': '10월 12일', 'duration': 0},
      {'date': '10월 13일', 'duration': 0},
      {'date': '10월 14일', 'duration': 0},
      {'date': '10월 15일', 'duration': 0},
      {'date': '10월 16일', 'duration': 0},
      {'date': '10월 17일', 'duration': 0},
      {'date': '10월 18일', 'duration': 0},
      {'date': '10월 19일', 'duration': 0},
      {'date': '10월 20일', 'duration': 0},
      {'date': '10월 21일', 'duration': 0},
      {'date': '10월 22일', 'duration': 0},
      {'date': '10월 23일', 'duration': 0},
      {'date': '10월 24일', 'duration': 0},
      {'date': '10월 25일', 'duration': 0},
      {'date': '10월 26일', 'duration': 0},
      {'date': '10월 27일', 'duration': 0},
      {'date': '10월 28일', 'duration': 0},
      {'date': '10월 29일', 'duration': 0},
      {'date': '10월 30일', 'duration': 0},
      {'date': '10월 31일', 'duration': 0},
      {'date': '11월 1일', 'duration': 0},
      {'date': '11월 2일', 'duration': 0},
      {'date': '11월 3일', 'duration': 0},
      {'date': '11월 4일', 'duration': 0},
      {'date': '11월 5일', 'duration': 4},
    ];

    return Scaffold(
      backgroundColor: lightGreyColor,
      appBar: AppBar(
        title: const Text(
          "공부 시간 통계",
          style: TextStyle(
            color: darkColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 오늘, 이번 주, 이번 달 요약 카드
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: SummaryCard(
                    icon: Icons.calendar_today_outlined,
                    title: '오늘',
                    value: '4분',
                    iconColor: Colors.blueAccent, // 이미지에서 보이는 색상
                  ),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: SummaryCard(
                    icon: Icons.show_chart,
                    title: '이번 주',
                    value: '4분',
                    iconColor: Colors.green, // 이미지에서 보이는 색상
                  ),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: SummaryCard(
                    icon: Icons.bar_chart,
                    title: '이번 달',
                    value: '4분',
                    iconColor: Colors.purpleAccent, // 이미지에서 보이는 색상
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 주간/월간 토글 버튼
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ToggleButtons(
                isSelected: [_selectedPeriod == 0, _selectedPeriod == 1],
                onPressed: (index) {
                  setState(() {
                    _selectedPeriod = index;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                selectedColor: Colors.white,
                fillColor: darkColor,
                color: Colors.grey, // 선택되지 않은 텍스트 색상
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                borderColor: Colors.transparent,
                selectedBorderColor: Colors.transparent,
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    child: Text('주간', style: TextStyle(fontSize: 16)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    child: Text('월간', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 데이터 목록
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 3,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedPeriod == 0 ? '최근 7일' : '최근 30일',
                    style: TextStyle(
                        color: darkColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  // 주간 또는 월간 데이터 표시
                  ...(_selectedPeriod == 0 ? weeklyData : monthlyData).map((data) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: StudyDurationBar(
                        date: data['date'],
                        durationMinutes: data['duration'],
                        maxDurationMinutes: 120, // 임시 최대 시간 (그래프 비율용)
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}