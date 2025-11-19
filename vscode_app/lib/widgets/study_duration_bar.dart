import 'package:flutter/material.dart';

class StudyDurationBar extends StatelessWidget {
  final String date;
  final int durationMinutes; // 분 단위
  final int maxDurationMinutes; // 그래프 비율 계산을 위한 최대 분

  const StudyDurationBar({
    super.key,
    required this.date,
    required this.durationMinutes,
    this.maxDurationMinutes = 180, // 기본 최대 3시간 (180분)
  });

  @override
  Widget build(BuildContext context) {
    const Color darkColor = Color(0xFF1A1A2E); // 주 색상 (네이비)

    // 공부 시간에 따른 바의 길이 비율
    double barWidthRatio = (durationMinutes / maxDurationMinutes).clamp(0.0, 1.0);
    if (durationMinutes == 0) barWidthRatio = 0.0; // 0분이면 바 길이도 0

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 80, // 날짜 텍스트 고정 폭
          child: Text(
            date,
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Stack(
            children: [
              // 배경 바
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              // 실제 공부 시간 바
              FractionallySizedBox(
                widthFactor: barWidthRatio,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent, // 바 색상
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        SizedBox(
          width: 40, // 시간 텍스트 고정 폭
          child: Text(
            '$durationMinutes분',
            textAlign: TextAlign.right,
            style: TextStyle(color: darkColor, fontSize: 15),
          ),
        ),
      ],
    );
  }
}