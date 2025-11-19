import firebase_admin
from firebase_admin import credentials, db
import numpy as np
import cv2
from tensorflow.keras.models import load_model
import time

# =========================
# 1️⃣ Firebase 초기화
# =========================
firebase_key_path = r"C:\Users\YunchanSeo\Desktop\cnn\cnn\csistudytracker-firebase-adminsdk-fbsvc-7950e57bd8.json"  # 변경 필요
firebase_url = 'https://csistudytracker-default-rtdb.asia-southeast1.firebasedatabase.app/'

if not firebase_admin._apps:
    cred = credentials.Certificate(firebase_key_path)
    firebase_admin.initialize_app(cred, {
        'databaseURL': firebase_url,
    })

# =========================
# 2️⃣ 모델 로드
# =========================
model_path = r"C:\Users\YunchanSeo\Desktop\cnn\cnn\capstone3.keras"  # 변경 필요
model = load_model(model_path)
class_labels = ['empty', 'sitdown']

# =========================
# 3️⃣ Firebase에서 CSI 패킷 가져오기 → 히트맵 변환
# =========================
def get_heatmap_from_firebase(category, index):
    ref = db.reference(f'/csidata/{category}/{index}')
    snapshot = ref.get()
    
    if not snapshot:
        return None
    
    csi_list = []
    for i in range(20):  # 최대 20 패킷
        key = f'packet_{i}'
        if key in snapshot:
            str_values = snapshot[key]
            float_values = [float(v) for v in str_values.split(',') if v.strip()]
            csi_list.append(float_values)
        else:
            return None  # 패킷 누락시 None 반환
    
    heatmap = np.array(csi_list)  # shape [20, 52] 가정
    # 히트맵 → CNN 입력용 변환
    resized = cv2.resize(heatmap, (224, 224), interpolation=cv2.INTER_LINEAR)
    rgb_image = np.stack([resized]*3, axis=-1)  # 채널 3개
    input_tensor = np.expand_dims(rgb_image.astype(np.float32), axis=0)  # [1,224,224,3]
    return input_tensor

# =========================
# 4️⃣ 모델 예측 및 Firebase 업로드
# =========================
def run_prediction(category, index):
    input_tensor = get_heatmap_from_firebase(category, index)
    if input_tensor is None:
        print(f"⚠️ 데이터 없음: {category}/{index}")
        return
    
    predictions = model.predict(input_tensor)
    pred_class = np.argmax(predictions)
    confidence = float(np.max(predictions))
    label = class_labels[pred_class]

    # Firebase에 예측 결과 저장
    pred_ref = db.reference(f'/prediction/{category}/{index}')
    pred_ref.set({
        'label': label,
        'confidence': confidence,
        'timestamp': int(time.time())
    })
    print(f"✅ {category}/{index} 예측 완료 → {label} ({confidence:.2f})")

# =========================
# 5️⃣ Firebase 리스너 (실시간 감지)
# =========================
def listener(event):
    if event.data is None:
        return
    
    path_parts = event.path.strip("/").split("/")
    if len(path_parts) == 2:
        category, index_str = path_parts
        try:
            index = int(index_str)
            print(f"\n🔥 새 CSI 데이터 감지: {category}/{index}")
            run_prediction(category, index)
        except ValueError:
            print(f"❌ index 변환 실패: {index_str}")

# =========================
# 6️⃣ 리스너 등록 및 대기
# =========================
ref = db.reference('/csidata')
ref.listen(listener)

print("✅ Firebase 실시간 감지 대기 중...")
while True:
    time.sleep(60)  # 리스너 유지
