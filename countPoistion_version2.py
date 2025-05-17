import pandas as pd
import math
import numpy as np

# ✅ 使用者輸入的測量值與對應 beacon 編號（1-based index）
# p_dbtest = [-61.57, -51.23, -57.67]  # RSSI (實測)
# beacon_seq = [1, 2, 3]               # 對應的 beacon 編號，必須按照數字順序，如:1、2、4或1、2、3...等

p_dbtest = [-65.42,-70.85, -55.91]  # RSSI (實測)
beacon_seq = [1, 2, 3]               # 對應的 beacon 編號，必須按照數字順序，如:1、2、4或1、2、3...等


# ✅ 第一步，讀取 CSV
input_file = 'C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0514\\pathLoss0514_output.csv'
df = pd.read_csv(input_file, header=None)

db0_values = []
path_loss_coeffs = []

for col in df.columns[1:]: # 從第2欄開始抓資料
    db0 = df.iloc[0, col]
    path_loss = df.iloc[1, col]
    db0_values.append(db0)
    path_loss_coeffs.append(path_loss)

# ✅ 第二步，抓出我們要的值，根據 beacon_seq
p_db0 = [db0_values[i - 1] for i in beacon_seq]
path_loss_coff = [path_loss_coeffs[i - 1] for i in beacon_seq]

# ✅ 第三步，計算距離
distance = []
for db0, db3, path_loss in zip(p_db0, p_dbtest, path_loss_coff):
    result = (db0 - db3) / (10 * path_loss)
    result_pow = math.pow(10, result)
    distance.append(result_pow)
    print(f"Distance to beacon: {result_pow:.3f} m")

# 三邊定位函數
def trilaterate(A, B, C, r1, r2, r3):
    ex = (B - A) / np.linalg.norm(B - A)
    i = np.dot(ex, C - A)
    ey = (C - A - i * ex)
    ey = ey / np.linalg.norm(ey)
    d = np.linalg.norm(B - A)
    j = np.dot(ey, C - A)

    x = (r1**2 - r2**2 + d**2) / (2 * d)
    y = (r1**2 - r3**2 + i**2 + j**2 - 2*i*x) / (2 * j)

    final_pos = A + x * ex + y * ey
    return final_pos

# Beacon 的實際座標（你可以改成 test a 的位置）
beacon_positions = {
    1: (3.5, 10.4),
    2: (0, 6.4),
    3: (5.6, 4.3),
    4: (2.4, 0),
}

# 根據 beacon_seq 取出三個座標
x1, y1 = beacon_positions[beacon_seq[0]]
x2, y2 = beacon_positions[beacon_seq[1]]
x3, y3 = beacon_positions[beacon_seq[2]]

# 建立三個 numpy 座標點
A = np.array([x1, y1])
B = np.array([x2, y2])
C = np.array([x3, y3])
r1, r2, r3 = distance

pos = trilaterate(A, B, C, r1, r2, r3)
print("📍 推算出的使用者座標：", pos)
