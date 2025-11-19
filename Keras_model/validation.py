import os
import cv2
import numpy as np
from tensorflow.keras.models import load_model
from sklearn.metrics import confusion_matrix, ConfusionMatrixDisplay
import matplotlib.pyplot as plt
import random

# ----------------- 설정 -----------------
model_path   = r"C:/Users/HyejinPark/Desktop/capstone_test4.keras"
image_folder = r"C:/Users/HyejinPark/Desktop/data/heatmap"
class_labels = ['vacant', 'studying', 'sleeping']  # 훈련 시 클래스
NUM_IMAGES   = 2700  # 검증에 사용할 이미지 수

IMG_SIZE   = 224
BATCH_SIZE = 8

# ----------------- 모델 로드 -----------------
model = load_model(model_path)
print("✅ 모델 로드 완료")

# ----------------- 이미지 전처리 함수 -----------------
def load_and_prepare(path):
    img = cv2.imread(path)
    if img is None:
        return None
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
    img = img.astype(np.float32) / 255.0
    return img

# ----------------- 검증 이미지 수집 -----------------
all_images = []
all_labels = []

# r_data 폴더 안의 모든 PNG 파일
files = [f for f in os.listdir(image_folder) if f.endswith('.png')]

# NUM_IMAGES 장 랜덤 선택
selected_files = random.sample(files, min(NUM_IMAGES, len(files)))

for f in selected_files:
    all_images.append(os.path.join(image_folder, f))
    
    # 파일 이름에 클래스명이 포함되어 있다고 가정
    if "vacant" in f.lower():
        all_labels.append(0)
    elif "studying" in f.lower():
        all_labels.append(1)
    elif "sleeping" in f.lower():
        all_labels.append(2)
    else:
        continue  # 혹시 이상한 파일명이 섞여 있으면 무시


# ----------------- 배치 단위 예측 -----------------
predicted_classes = []

for s in range(0, len(all_images), BATCH_SIZE):
    batch_paths = all_images[s:s + BATCH_SIZE]
    batch_imgs = []
    for path in batch_paths:
        img = load_and_prepare(path)
        if img is not None:
            batch_imgs.append(img)

    if not batch_imgs:
        continue

    batch_imgs = np.stack(batch_imgs, axis=0)
    probs = model.predict(batch_imgs, verbose=0)
    batch_pred = np.argmax(probs, axis=1)
    predicted_classes.extend(batch_pred)

predicted_classes = np.array(predicted_classes)

# ----------------- 전체 정확도 -----------------
accuracy = np.sum(predicted_classes == all_labels) / len(predicted_classes)
print(f"\n총 검증 정확도: {accuracy*100:.2f}%")

# ----------------- 맞춘/틀린 개수 -----------------
correct_count = np.sum(predicted_classes == all_labels)
incorrect_count = len(predicted_classes) - correct_count
print(f"맞춘 개수: {correct_count}, 틀린 개수: {incorrect_count}")

# ----------------- 혼동 행렬 시각화 -----------------
cm = confusion_matrix(all_labels, predicted_classes, labels=range(len(class_labels)))
disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=class_labels)
disp.plot(cmap=plt.cm.Blues)
plt.title("Confusion Matrix ")
plt.show()
