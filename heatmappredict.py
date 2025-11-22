import firebase_admin
from firebase_admin import credentials, db
import numpy as np
import cv2
from tensorflow.keras.models import load_model
import time
from datetime import datetime

# =========================
# 1️⃣ 환경 설정 및 초기화
# =========================
# [설정] Firebase 키 경로 (사용자 환경에 맞게 유지)
firebase_key_path = r"C:\Users\YunchanSeo\Desktop\cnn\cnn\csistudytracker-firebase-adminsdk-fbsvc-7950e57bd8.json" 
firebase_url = 'https://csistudytracker-default-rtdb.asia-southeast1.firebasedatabase.app/'

# [설정] 모델 경로
model_path = r"C:\Users\YunchanSeo\Desktop\cnn\cnn\capstone3.keras"

# [설정] 현재 실제 상태 (Ground Truth) - 테스트 시 수동 변경
CURRENT_ACTUAL_STATE = "studying"

if not firebase_admin._apps:
    cred = credentials.Certificate(firebase_key_path)
    firebase_admin.initialize_app(cred, {
        'databaseURL': firebase_url,
    })

# =========================
# 2️⃣ 모델 로드
# =========================
try:
    model = load_model(model_path)
    class_labels = ['empty', 'sitdown'] # 라벨 순서 확인 필요
    print(f"✅ 모델 로드 성공: {model_path}")
except Exception as e:
    print(f"❌ 모델 로드 실패: {e}")
    exit()

# =========================
# 3️⃣ Firebase에서 CSI 패킷 가져오기 → 히트맵 변환
# =========================
def get_heatmap_from_firebase(category, index):
    ref = db.reference(f'/csidata/{category}/{index}')
    snapshot = ref.get()
    
    if not snapshot:
        return None
    
    csi_list = []
    # 패킷 순서대로 정렬하여 가져오기 (packet_0 ~ packet_19)
    for i in range(20): 
        key = f'packet_{i}'
        if key in snapshot:
            str_values = snapshot[key]
            try:
                float_values = [float(v) for v in str_values.split(',') if v.strip()]
                csi_list.append(float_values)
            except ValueError:
                print(f"⚠️ 데이터 파싱 오류: {key}")
                return None
        else:
            return None  # 패킷 하나라도 누락되면 None 반환
    
    try:
        heatmap = np.array(csi_list)  # 예상 shape: [20, 52] (서브캐리어 수에 따라 다름)
        
        # 히트맵 → CNN 입력용 변환 (Resize & RGB Stacking)
        resized = cv2.resize(heatmap, (224, 224), interpolation=cv2.INTER_LINEAR)
        
        # Min-Max Normalization (이미지화 전 정규화 권장)
        norm_image = cv2.normalize(resized, None, 0, 255, cv2.NORM_MINMAX)
        norm_image = norm_image.astype(np.uint8)
        
        rgb_image = np.stack([norm_image]*3, axis=-1)  # 채널 3개로 복사
        input_tensor = np.expand_dims(rgb_image.astype(np.float32) / 255.0, axis=0)  # [1,224,224,3], 0~1 스케일링
        
        return input_tensor
    except Exception as e:
        print(f"❌ 전처리 중 오류: {e}")
        return None

# =========================
# 4️⃣ 모델 예측 및 Firebase 업로드 (수정됨)
# =========================
def run_prediction(category, index):
    input_tensor = get_heatmap_from_firebase(category, index)
    if input_tensor is None:
        print(f"⚠️ 데이터 없음: {category}/{index}")
        return
    
    # 예측 수행
    predictions = model.predict(input_tensor, verbose=0)
    pred_class = np.argmax(predictions)
    confidence_score = float(np.max(predictions))
    predicted_label = class_labels[pred_class]

    # [수정] Firebase 업로드 포맷 변경 (heatmap_predictions 구조에 맞춤)
    # confidence: 0~1 -> 0~100 정수 변환
    # timestamp: Unix timestamp -> "YYYY-MM-DD HH:MM:SS" 문자열
    
    current_time_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    upload_data = {
        'confidence': int(confidence_score * 100),
        'input_state': CURRENT_ACTUAL_STATE,      # 현재 설정된 정답 상태
        'predicted_label': predicted_label,       # 모델이 예측한 값
        'timestamp': current_time_str
    }

    # [수정] /heatmap_predictions 경로에 push()로 저장
    try:
        pred_ref = db.reference('/heatmap_predictions')
        new_ref = pred_ref.push()
        new_ref.set(upload_data)
        
        # 원래 출력문 스타일 유지 + 정보 업데이트
        print(f"✅ {category}/{index} 예측 완료 → {predicted_label} ({int(confidence_score*100)}%) | 저장됨")
        
    except Exception as e:
        print(f"❌ Firebase 업로드 실패: {e}")

# =========================
# 5️⃣ Firebase 리스너 (실시간 감지)
# =========================
def listener(event):
    if event.data is None:
        return
    
    # 경로 파싱 (/csidata/{category}/{index} 변경 감지)
    path_parts = event.path.strip("/").split("/")
    
    # 예: /realtime/1731412345 와 같은 형태가 들어올 때
    if len(path_parts) == 2:
        category, index_str = path_parts
        try:
            # index가 숫자인지 확인 (타임스탬프 등)
            index = int(index_str) # 혹은 문자열 그대로 사용 가능하면 이 줄 제거
            
            print(f"\n🔥 새 CSI 데이터 감지: {category}/{index}")
            run_prediction(category, index_str) # index_str 그대로 전달
            
        except ValueError:
            # index가 숫자가 아닌 경우 무시하거나 로그 출력
            # print(f"❌ index 변환 실패: {index_str}")
            pass
    
    # 데이터가 한꺼번에 로드될 때 (초기 실행 등) 최하위 노드 감지 로직 필요시 추가

# =========================
# 6️⃣ 리스너 등록 및 대기
# =========================
ref = db.reference('/csidata')
try:
    ref.listen(listener)
    print("✅ Firebase 실시간 감지 대기 중... (/csidata)")
    print(f"🎯 예측 결과 저장 경로: /heatmap_predictions")
    
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("\n🛑 프로그램 종료")
