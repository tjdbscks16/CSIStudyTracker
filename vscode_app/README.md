# 📘 CSI Study Tracker
# NAME : TEMPO
WiFi CSI 기반 행동 인식으로 **공부·휴식 시간을 자동 측정**하는 Flutter 앱입니다.  
앱이 공부/자리이탈/수면 상태를 자동 감지하여 시간을 기록합니다.

---

## 🚀 주요 기능

### ✔ 자동 행동 인식 타이머
- CSI + CNN 모델로 행동 감지  
- studying / vacant / sleeping 자동 분류  
- 상태 변화에 따라 타이머 자동 시작/일시정지  

### ✔ 오늘의 기록
- 공부·휴식 시간 표시  
- 휴식 비율 기반 집중도 평가  
- Firebase에 날짜별 기록 자동 저장  

### ✔ 주간·월간 통계
- 최근 7일 그래프  
- 휴식 비율 기반 분석  

---

## 🔧 기술 스택
- Flutter / Dart  
- Firebase Realtime Database  
- Python / TensorFlow  
- Raspberry Pi + Nexmon CSI Patch  

---

## 📂 데이터 구조
```
/heatmap_predictions/{ts}/predicted_label

/records/{YYYY-MM-DD}/
    study_time
    break_time
```

---

## 🛠 실행 방법
1. Firebase Init 후 `firebase_options.dart` 생성  
2. 패키지 설치:
```
flutter pub get
```
3. 실행:
```
flutter run
```

---

## 👤 개발자
**Yunchan Seo — Hallym University Big Data Major**  
GitHub: https://github.com/tjdbscks16
