import math
import numpy as np

p_db0 = [-53.18, -48.28, -50.18]
p_dbtest = [-56.11, -53.65, -57.39] #手動輸入的
path_loss_coff = [0.929, 1.363, 1.663]
distance = []
#先計算跟每一個beacon 的距離
for db0, db3, path_loss in zip(p_db0, p_dbtest, path_loss_coff):
    result = (db0 - db3)/(10 * path_loss)
    result_pow = math.pow(10, result)
    distance.append(result_pow)
    print(f"distance: {result_pow}")

# 計算中間變數
def trilaterate(A, B, C, r1, r2, r3):
    # 兩向量
    ex = (B - A) / np.linalg.norm(B - A)
    i = np.dot(ex, C - A)
    ey = (C - A - i * ex)
    ey = ey / np.linalg.norm(ey)
    d = np.linalg.norm(B - A)
    j = np.dot(ey, C - A)

    # 坐標計算
    x = (r1**2 - r2**2 + d**2) / (2 * d)
    y = (r1**2 - r3**2 + i**2 + j**2 - 2*i*x) / (2 * j)

    # 回推原始座標
    final_pos = A + x * ex + y * ey
    return final_pos

# 假設三點如下（請自行替換成實際值）
x1, y1 = 3.2, 9.6
x2, y2 = 0, 6.4
x3, y3 = 5.6, 4.8  # 約等於 equilateral triangle

# 已知三個點的位置
A = np.array([x1, y1])
B = np.array([x2, y2])
C = np.array([x3, y3])

# 與三個點的距離
r1 = distance[0]
r2 = distance[1]
r3 = distance[2]

pos = trilaterate(np.array([x1, y1]), np.array([x2, y2]), np.array([x3, y3]), r1, r2, r3)
print("推算出的使用者座標：", pos)
