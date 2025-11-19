import 'package:flutter/material.dart';
import 'package:vscode_app/screens/timer_page.dart';
import 'package:vscode_app/screens/records_page.dart';
import 'package:vscode_app/screens/stats_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 현재 선택된 탭 인덱스

  // 탭별로 보여줄 페이지 목록
  static const List<Widget> _widgetOptions = <Widget>[
    TimerPage(), // 0번 탭: 타이머
    RecordsPage(), // 1번 탭: 기록
    StatsPage(), // 2번 탭: 통계
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex), // 선택된 탭에 해당하는 페이지 표시
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            activeIcon: Icon(Icons.timer), // 선택 시 채워진 아이콘
            label: '타이머',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined), // 기록 아이콘 변경
            activeIcon: Icon(Icons.receipt_long),
            label: '기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: '통계',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
