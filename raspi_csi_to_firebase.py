import os
import time
import numpy as np
import firebase_admin
from firebase_admin import credentials, db
from nexcsi import decoder  # Nexmon CSI decoder 라이브러리

# =========================
# 환경 설정
# =========================
CAP_DIR = "/home/pi/capston/"  # pcap 파일 저장 폴더
PACKET_COUNT = 20  # 한번에 캡처할 패킷 수
DEVICE = "raspberry"  # Nexmon 장치 종류 (라즈베리파이)

# Firebase 서비스 계정 경로
firebase_key_path = "/home/pi/firebase_key.json"

# Firebase DB URL
firebase_url = 'https://csistudytracker-default-rtdb.asia-southeast1.firebasedatabase.app/'

# =========================
# Firebase 초기화
# =========================
if not firebase_admin._apps:
    cred = credentials.Certificate(firebase_key_path)
    firebase_admin.initialize_app(cred, {
        'databaseURL': firebase_url
    })

# =========================
# Nexmon Decoder 초기화
# =========================
csi_decoder = decoder(DEVICE)

# =========================
# CSI 전처리 및 업로드 (수정됨)
# =========================
def upload_csi_to_firebase(pcap_file, timestamp_id):
    """
    캡처된 pcap 파일에서 CSI를 추출하고, 고정된 경로에 업로드합니다.
    - 경로: /csidata/realtime/{timestamp_id}
    """
    try:
        # 1️⃣ pcap 파일에서 CSI 읽기
        samples = csi_decoder.read_pcap(pcap_file)
        csi_list = csi_decoder.unpack(samples['csi'], zero_nulls=True, zero_pilots=True)

        # ❗️ 서버 리스너가 감지할 수 있도록 'realtime' 카테고리와 타임스탬프 ID를 사용
        ref = db.reference(f"/csidata/realtime/{timestamp_id}")

        # 2️⃣ 전처리된 amplitude Firebase 업로드
        # 서버에서 20개의 패킷을 모두 사용하므로, 20개를 전부 전송합니다.
        for i, csi_entry in enumerate(csi_list[:PACKET_COUNT]):
            amplitudes = np.abs(csi_entry)  # 복소수 CSI → 크기
            if amplitudes.size == 0:
                continue
            
            amplitudes_list = amplitudes.flatten().tolist()
            # 각 패킷을 packet_0, packet_1, ... 노드로 저장
            ref.child(f"packet_{i}").set(",".join(map(str, amplitudes_list)))

        print(f"✅ 실시간 데이터 전송 완료 (ID: {timestamp_id})")

    except Exception as e:
        print(f"❌ 업로드 실패: {e}")

# =========================
# 메인 루프 (수정됨)
# =========================
def capture_and_upload():
    """
    CSI 패킷을 주기적으로 캡처하고 Firebase에 업로드하는 메인 루프.
    """
    while True:
        # 현재 시간을 고유 ID로 사용
        timestamp_id = int(time.time())
        pcap_path = os.path.join(CAP_DIR, f"csi_{timestamp_id}.pcap")

        # 1️⃣ tcpdump로 CSI 패킷 캡처
        # print("[DEBUG] 패킷 캡처 시작...")
        os.system(f"sudo tcpdump -i wlan0 -s 0 -c {PACKET_COUNT} -w {pcap_path} udp port 5500")
        # print("[DEBUG] 패킷 캡처 완료")

        # 2️⃣ Firebase 업로드
        upload_csi_to_firebase(pcap_path, timestamp_id)

        # 3️⃣ pcap 파일 삭제
        os.remove(pcap_path)
        # print(f"[DEBUG] {pcap_path} 삭제 완료\n")

        # 1초 대기 (실시간 예측 서비스에 적합한 간격)
        time.sleep(1)

# =========================
# 실행
# =========================
if __name__ == "__main__":
    os.makedirs(CAP_DIR, exist_ok=True)
    print("🚀 [실시간 예측 모드] CSI 데이터 전송을 시작합니다...")
    try:
        capture_and_upload()
    except KeyboardInterrupt:
        print("\n[INFO] 프로그램을 종료합니다.")