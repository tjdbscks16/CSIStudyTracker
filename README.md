

# 📚 CSIStudyTracker: WiFi CSI를 활용한 자동 학습 관리 시스템

<p align="center">
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python Badge">
  <img src="https://img.shields.io/badge/Keras-D00000?style=for-the-badge&logo=keras&logoColor=white" alt="Keras Badge">
  <img src="https://img.shields.io/badge/TensorFlowLite-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white" alt="TensorFlow Lite Badge">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter Badge">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase Badge">
</p>

**CSIStudyTracker**는 WiFi CSI (Channel State Information)를 활용하여 
학습자의 실시간 학습 상태를 자동으로 인식하고, **순공부 시간**을 측정해주는 혁신적인 학습 관리 시스템입니다. 
이 시스템은 라즈베리파이에서 CSI 데이터를 수집하고, 
이를 기반으로 사용자의 **집중, 이탈, 졸음** 상태를 예측하여 Firebase에 저장합니다. 
학습자는 Flutter 앱을 통해 자신의 학습 상태와 순공부 시간을 실시간으로 확인할 수 있습니다.

-----

## 🎯 프로젝트 목표

  - **자동 학습 상태 인식**: 학습자가 자리에 앉아 있는지, 집중하고 있는지, 졸거나 자리에서 이탈했는지를 자동으로 인식합니다.
  - **실시간 학습 기록**: 인식된 학습 상태를 Firebase에 실시간으로 기록합니다.
  - **순공부 시간 측정**: 사용자의 집중 상태를 기준으로 정확한 순공부 시간을 계산합니다.
  - **시각화 및 통계 제공**: Flutter 앱을 통해 실시간 학습 상태 및 통계 데이터를 확인하고 관리할 수 있습니다.

-----

## 💻 시스템 구조

CSIStudyTracker의 시스템은 크게 **데이터 수집 및 처리**, **예측 및 저장**, **실시간 동기화 및 시각화** 세 부분으로 나뉩니다.

1.  **라즈베리파이**: 📶 WiFi CSI 패킷을 수집하고 `.pcap` 파일을 생성합니다.
2.  **Python 스크립트**: 🧑‍💻 `.pcap` 파일에서 페이로드(payload)를 추출하여 AI 모델의 입력 변수로 변환합니다.
3.  **모델 예측**: 🧠 PyTorch 또는 TensorFlow Lite로 경량화된 모델이 데이터를 분석하여 사용자의 `status`와 `score`를 예측합니다.
4.  **Firebase Realtime Database**: ☁️ 예측 결과를 실시간으로 데이터베이스에 저장합니다.
5.  **Flutter 앱**: 📱 Firebase Realtime Database를 실시간으로 구독하여 UI에 현재 학습 상태를 즉시 반영하고 통계를 시각화합니다.

-----

## 🛠️ 사용 기술

  - **데이터 수집**: 라즈베리파이 + WiFi CSI
  - **데이터 처리 및 모델**: Python, Scapy
  - **모델**: Keras (TensorFlow) / TensorFlow Lite (경량화)
  - **데이터베이스**: Firebase Realtime Database
  - **앱 개발**: Flutter

-----

## ✨ 주요 특징

  - **엣지 컴퓨팅**: 라즈베리파이에서 직접 모델을 추론하여 실시간으로 학습 상태를 예측합니다.
  - **실시간 데이터 동기화**: Firebase를 통해 웹 및 모바일 앱 간에 데이터가 즉시 동기화됩니다.
  - **정밀한 순공부 시간 측정**: 단순한 타이머가 아닌, 사용자의 실제 집중 상태를 기반으로 순공부 시간을 계산합니다.
  - **즉각적인 피드백**: 앱을 통해 현재 학습 상태에 대한 즉각적인 피드백을 받을 수 있습니다.

-----

## 🚀 설치 및 실행 방법

### 1\. 라즈베리파이 환경 준비

라즈베리파이에서 필요한 라이브러리를 설치합니다.

```bash
sudo apt update
sudo apt install python3-pip
pip3 install firebase-admin scapy
```

### 2\. Firebase 설정

1.  Firebase 프로젝트를 생성하고, **Firebase Realtime Database**를 활성화합니다.
2.  **서비스 계정**을 생성하고 JSON 파일을 다운로드합니다.
3.  다운로드한 JSON 파일을 라즈베리파이의 특정 경로(`home/pi/firebase_key.json`)에 저장합니다.

### 3\. 스크립트 실행

CSI `.pcap` 파일을 저장할 폴더를 생성하고 Python 스크립트를 실행합니다.

```bash
mkdir -p /home/pi/capston/
python3 process_pcap.py
```


-----

## 📝 참고 사항

  - **보안 규칙**: 실제 배포 시에는 반드시 Firebase 보안 규칙을 적절하게 수정하여 데이터 접근을 제한해야 합니다.
  - **최적화**: 라즈베리파이의 성능을 고려하여 모델을 TensorFlow Lite 등으로 **경량화**하고 최적화하는 것이 중요합니다.

프로젝트에 대한 추가적인 문의사항이 있으시면 언제든지 Issues에 남겨주세요\! 🧑‍💻
