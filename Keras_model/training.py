import os
import numpy as np
import cv2
import matplotlib.pyplot as plt
from keras.utils import to_categorical
from sklearn.model_selection import train_test_split
from c_cnn import cnn_capstone  # cnn.py에 정의된 함수
from keras.callbacks import EarlyStopping

# -----------------------------
# 경로 및 카테고리 설정
# -----------------------------
image_folder = r"C:/Users/HyejinPark/Desktop/data/heatmap"
categories = ['vacant', 'studying', 'sleeping']

images = []
labels = []
count_per_category = {category: 0 for category in categories}

# -----------------------------
# 폴더별 이미지 로딩
# -----------------------------
files = [f for f in os.listdir(image_folder) if os.path.isfile(os.path.join(image_folder, f))]

for filename in files:
    img_path = os.path.join(image_folder, filename)
    img = cv2.imread(img_path)
    if img is None:
        print(f"[경고] 이미지 읽기 실패: {img_path}")
        continue

    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img = cv2.resize(img, (224, 224))

    # 파일명에 포함된 카테고리 이름으로 라벨 지정
    label_idx = None
    for category_idx, category in enumerate(categories):
        if category in filename.lower():
            label_idx = category_idx
            count_per_category[category] += 1
            break

    if label_idx is None:
        print(f"[경고] 카테고리 구분 불가: {filename}")
        continue

    images.append(img)
    labels.append(label_idx)

# -----------------------------
# 데이터 확인 및 전처리
# -----------------------------
images = np.array(images, dtype=np.float32) / 255.0
labels = np.array(labels)

print(f"총 이미지 수: {len(images)}")
for cat in categories:
    print(f"{cat} 개수: {count_per_category[cat]}")

if len(images) == 0:
    raise ValueError("이미지를 하나도 로드하지 못했습니다. 경로와 파일 이름을 확인하세요.")

# -----------------------------
# 데이터 분할 (훈련:검증 = 8:2)
# -----------------------------
X_train, X_test, Y_train, Y_test = train_test_split(
    images, labels, test_size=0.2, stratify=labels, random_state=42
)

# 원-핫 인코딩
Y_train = to_categorical(Y_train, num_classes=len(categories))
Y_test = to_categorical(Y_test, num_classes=len(categories))

# -----------------------------
# 모델 생성
# -----------------------------
model = cnn_capstone(input_shape=(224, 224, 3), num_classes=len(categories))


# -----------------------------
# EarlyStopping 설정
# -----------------------------
early_stop = EarlyStopping(
    monitor='val_loss',        # 검증 손실이 개선되지 않으면 멈춤
    patience=5,                # 5 epoch 동안 개선이 없으면 종료
    restore_best_weights=True  # 가장 성능 좋았던 모델 가중치 복원
)

# -----------------------------
# 학습
# -----------------------------
history = model.fit(
    X_train, Y_train,
    validation_data=(X_test, Y_test),
    epochs=20,
    batch_size=8,
    verbose=1,
    callbacks=[early_stop]
)

# -----------------------------
# 평가
# -----------------------------
val_loss, val_acc = model.evaluate(X_test, Y_test, verbose=1)
print(f"\n최종 Training 정확도: {history.history['accuracy'][-1]*100:.2f}%")
print(f"최종 Validation 정확도: {val_acc*100:.2f}%")

# -----------------------------
# 정확도/손실 시각화
# -----------------------------
epochs_range = range(1, len(history.history['accuracy']) + 1)

plt.figure(figsize=(12, 5))

plt.subplot(1, 2, 1)
plt.plot(epochs_range, history.history['accuracy'], label='Training Accuracy')
plt.plot(epochs_range, history.history['val_accuracy'], label='Validation Accuracy')
plt.title('Accuracy per Epoch')
plt.xlabel('Epoch')
plt.ylabel('Accuracy')
plt.legend()

plt.subplot(1, 2, 2)
plt.plot(epochs_range, history.history['loss'], label='Training Loss')
plt.plot(epochs_range, history.history['val_loss'], label='Validation Loss')
plt.title('Loss per Epoch')
plt.xlabel('Epoch')
plt.ylabel('Loss')
plt.legend()

plt.tight_layout()
plt.savefig('C:/Users/HyejinPark/Desktop/capstoneimg1.png', dpi=300)
plt.show()

# -----------------------------
# 모델 저장
# -----------------------------
model.save('C:/Users/HyejinPark/Desktop/capstone_test4.keras')
print("모델 저장 완료!")




#------------------------------
# capstone_test - 새로운 데이터셋 (500,500,500)
# capstone3 - 이전 (처음) 데이터셋
#------------------------------
