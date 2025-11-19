import 'package:flutter/material.dart';

// 타이머 페이지의 상태를 정의하는 enum
enum TimerState { initial, loading, running }

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  TimerState _currentState = TimerState.initial; // 초기 상태: 시작 전
  String _currentTime = '00:00:00'; // 타이머 시간
  bool _isStudyingDetected = false; // 공부 중 감지 여부

  // TODO: 실제 AI 모델 예측 및 타이머 로직을 여기에 통합해야 합니다.
  // 이 예제에서는 UI 상태 변화만 보여줍니다.

  @override
  Widget build(BuildContext context) {
    const Color darkColor = Color(0xFF1A1A2E); // 주 색상 (네이비)
    const Color lightGreyColor = Color(0xFFF3F4F8); // 배경색

    Widget buildContent() {
      switch (_currentState) {
        case TimerState.initial:
          return _buildInitialState(darkColor); // Image 1
        case TimerState.loading:
          return _buildLoadingState(darkColor); // Image 4
        case TimerState.running:
          return _buildRunningState(darkColor); // Image 5
      }
    }

    return Scaffold(
      backgroundColor: lightGreyColor,
      appBar: AppBar(
        title: const Text(
          "습관을 인식하다. 변화를 만들다",
          style: TextStyle(
            color: darkColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: buildContent(),
      ),
    );
  }

  // Image 1: 시작하기 버튼이 있는 초기 상태 UI
  Widget _buildInitialState(Color darkColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildTimerCircle(darkColor, '공부 시간', _currentTime, false),
        const SizedBox(height: 60),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _currentState = TimerState.loading; // 로딩 상태로 전환
              // TODO: AI 모델 연동 시작 로직 호출
              Future.delayed(const Duration(seconds: 3), () {
                setState(() {
                  _currentState = TimerState.running; // 3초 후 타이머 동작 상태로 전환
                  _isStudyingDetected = true; // 공부 감지 시작
                });
              });
            });
          },
          icon: const Icon(Icons.play_arrow, color: Colors.white),
          label: const Text(
            '시작하기',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: darkColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 18),
          ),
        ),
      ],
    );
  }

  // Image 4: 행동 인식 중 로딩 상태 UI
  Widget _buildLoadingState(Color darkColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            strokeWidth: 5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 30),
        Text(
          '행동인식중~',
          style: TextStyle(fontSize: 20, color: darkColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Image 5: 타이머 동작 중 상태 UI
  Widget _buildRunningState(Color darkColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildTimerCircle(darkColor, '공부 시간', '00:00:07', true), // 예시 시간
        const SizedBox(height: 60),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: 일시정지 로직
            setState(() {
              _currentState = TimerState.initial; // 예시: 초기 상태로 돌아감
            });
          },
          icon: Icon(Icons.pause, color: darkColor),
          label: Text(
            '일시정지',
            style: TextStyle(fontSize: 18, color: darkColor),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 18),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: 초기화 로직
            setState(() {
              _currentState = TimerState.initial;
              _currentTime = '00:00:00';
              _isStudyingDetected = false;
            });
          },
          icon: Icon(Icons.refresh, color: darkColor),
          label: Text(
            '초기화',
            style: TextStyle(fontSize: 18, color: darkColor),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 18),
          ),
        ),
      ],
    );
  }

  // 타이머 원형 UI를 재사용하기 위한 헬퍼 위젯
  Widget _buildTimerCircle(
      Color darkColor, String title, String time, bool showDetectionStatus) {
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            time,
            style: TextStyle(
              color: darkColor,
              fontSize: 50,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showDetectionStatus) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _isStudyingDetected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isStudyingDetected ? '공부 중 감지' : '미감지',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}