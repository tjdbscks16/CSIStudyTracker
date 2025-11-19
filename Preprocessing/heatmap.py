from nexcsi import decoder
import os
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

device = "raspberrypi"  # nexus5, nexus6p, rtac86u

# 카테고리 순서 지정
categories = ['vacant', 'studying','sleeping']
#categories = ['vacant', 'studying']

# 폴더 경로
pcap_folder = r'C:/Users/HyejinPark/Desktop/data'   # PCAP 파일 폴더
csv_folder = r'C:/Users/HyejinPark/Desktop/data'  # CSV 저장 폴더
image_folder = r'C:/Users/HyejinPark/Desktop/data/heatmap'  # 히트맵 이미지 폴더

# 폴더 없으면 생성
os.makedirs(csv_folder, exist_ok=True)
os.makedirs(image_folder, exist_ok=True)

################################
#### 전처리 및 CSV 파일 생성 ####
################################

for category in categories:
    # 카테고리별 폴더 대신 capstone 폴더에 바로 저장
    for i in range(1, 1001):   
        pcap_file_path = os.path.join(pcap_folder, f'{category}{i}.pcap')
        
        if not os.path.exists(pcap_file_path):
            print(f"File not found: {pcap_file_path}, skipping...")
            continue

        # PCAP 읽기
        samples = decoder(device).read_pcap(pcap_file_path)
        csi = decoder(device).unpack(samples['csi'], zero_nulls=True, zero_pilots=True)

        db_amplitudes_list = []

        for index in range(len(csi)):
            csi_filtered = csi[index][(csi[index].real != 0) | (csi[index].imag != 0)]
            if csi_filtered.size > 0:
                amplitudes = np.abs(csi_filtered)
                db_values = 20 * np.log10(np.where(amplitudes > 0, amplitudes, np.nan))
                mean_val = np.nanmean(db_values)
                db_values = np.where(db_values > 70, mean_val, db_values)
                db_amplitudes_list.append(db_values)

        # CSV 저장 (capstone 폴더 바로 아래에 저장)
        csv_file_path = os.path.join(csv_folder, f'{category}{i}.csv')
        with open(csv_file_path, 'w') as f:
            for db_amplitudes in db_amplitudes_list:
                f.write(','.join(map(str, db_amplitudes)) + '\n')

        ################################
        ###### 히트맵 생성 및 저장 ######
        ################################
        data = pd.DataFrame(db_amplitudes_list[:20])

        plt.figure(figsize=(12, 8))
        sns.heatmap(data, cmap='coolwarm', cbar=True, xticklabels=10, yticklabels=10)

        # PNG 저장 (capstone 폴더 바로 아래에 저장)
        save_path = os.path.join(image_folder, f'{category}{i}.png')
        plt.savefig(save_path)
        plt.close()

        print(f"Processed: {pcap_file_path}")
        print(f"CSV saved: {csv_file_path}")
        print(f"Heatmap saved: {save_path}")
