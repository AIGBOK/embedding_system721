import pandas as pd
import math
import numpy as np

# === 讀取 RSSI 測試檔 ===
input_file_rssi = 'C:\\Users\\Lab721\\Desktop\\embedding_system721-main\\embedding_system721-main\\Documents0520\\0520_rssi_testoutput.csv'
df_rssi = pd.read_csv(input_file_rssi, header=None)

# 擷取每組 RSSI
p_dbtest = []
i = 0
while i < len(df_rssi):
    if str(df_rssi.iloc[i, 0]).strip() == 'time range':
        dBm_values = df_rssi.iloc[i+1:i+5, 2].astype(float).tolist()
        p_dbtest.append(dBm_values)
        i += 5
    else:
        i += 1

# === 讀取 path loss model ===
input_file_pathloss = 'C:\\Users\\Lab721\\Desktop\\embedding_system721-main\\embedding_system721-main\\Documents0520\\pathLoss0520_output.csv'
df_path = pd.read_csv(input_file_pathloss, header=None)

db0_path1 = df_path.iloc[0, 1:].astype(float).tolist()
path_loss1 = df_path.iloc[1, 1:].astype(float).tolist()
db0_path2 = df_path.iloc[2, 1:].astype(float).tolist()
path_loss2 = df_path.iloc[3, 1:].astype(float).tolist()

# === beacon 座標 ===
beacon_positions = {
    1: (3.5, 10.4),
    2: (0, 6.4),
    3: (5.6, 4.3),
    4: (2.4, 0),
}

# === 測試點座標 ===
test_points = [
    (0.8, 8),
    (4, 8),
    (0.8, 4),
    (3.2, 4.8),
    (0.8, 2.4),
    (4, 2.4),
    (2.4, 2.4)
]

# === 定義三角定位函式 ===
def trilateration(p1, r1, p2, r2, p3, r3):
    x1, y1 = p1
    x2, y2 = p2
    x3, y3 = p3
    A = np.array([
        [2 * (x2 - x1), 2 * (y2 - y1)],
        [2 * (x3 - x1), 2 * (y3 - y1)]
    ])
    b = np.array([
        r1**2 - r2**2 - x1**2 + x2**2 - y1**2 + y2**2,
        r1**2 - r3**2 - x1**2 + x3**2 - y1**2 + y3**2
    ])
    try:
        x, y = np.linalg.solve(A, b)
        return round(x, 3), round(y, 3)
    except np.linalg.LinAlgError:
        return None, None

# === 主處理 ===
results = []

for idx, group in enumerate(p_dbtest, 1):
    sorted_vals = sorted(enumerate(group, start=1), key=lambda x: x[1], reverse=True)[:3]
    beacon_seq = [i for i, _ in sorted_vals]
    rssi_vals = [val for _, val in sorted_vals]

    # 選擇 path1 或 path2
    p_db0 = []
    path_loss_coff = []

    # 把 beacon_seq 和對應 RSSI 值打包，方便條件判斷
    beacon_rssi = dict(zip(beacon_seq, rssi_vals))

    if set(beacon_seq) == {2, 3, 4}:
        if beacon_rssi[2] > beacon_rssi[3]:
            for b in beacon_seq:
                if b == 4:
                    p_db0.append(db0_path1[b - 1])
                    path_loss_coff.append(path_loss1[b - 1])
                else:
                    p_db0.append(db0_path2[b - 1])
                    path_loss_coff.append(path_loss2[b - 1])
        else:
            for b in beacon_seq:
                if b == 4:
                    p_db0.append(db0_path2[b - 1])
                    path_loss_coff.append(path_loss2[b - 1])
                else:
                    p_db0.append(db0_path2[b - 1])
                    path_loss_coff.append(path_loss2[b - 1])

    elif set(beacon_seq) == {1, 3, 4}:
        if beacon_rssi[1] > beacon_rssi[4]:
            for b in beacon_seq:
                if b == 3:
                    p_db0.append(db0_path1[b - 1])
                    path_loss_coff.append(path_loss1[b - 1])
                else:
                    p_db0.append(db0_path2[b - 1])
                    path_loss_coff.append(path_loss2[b - 1])
        else:
            for b in beacon_seq:
                if b == 3:
                    p_db0.append(db0_path2[b - 1])
                    path_loss_coff.append(path_loss2[b - 1])
                else:
                    p_db0.append(db0_path2[b - 1])
                    path_loss_coff.append(path_loss2[b - 1])

    elif set(beacon_seq) == {1, 2, 4}:
        if beacon_rssi[1] > beacon_rssi[4]:
            for b in beacon_seq:
                if b == 2:
                    p_db0.append(db0_path1[b - 1])
                    path_loss_coff.append(path_loss1[b - 1])
                else:
                    p_db0.append(db0_path1[b - 1])
                    path_loss_coff.append(path_loss1[b - 1])
        else:
            for b in beacon_seq:
                if b == 2:
                    p_db0.append(db0_path2[b - 1])
                    path_loss_coff.append(path_loss2[b - 1])
                else:
                    p_db0.append(db0_path1[b - 1])
                    path_loss_coff.append(path_loss1[b - 1])

    elif set(beacon_seq) == {1, 2, 3}:
        if beacon_rssi[2] > beacon_rssi[3]:
            for b in beacon_seq:
                if b == 1:
                    p_db0.append(db0_path1[b - 1])
                    path_loss_coff.append(path_loss1[b - 1])
                else:
                    p_db0.append(db0_path1[b - 1])
                    path_loss_coff.append(path_loss1[b - 1])
        else:
            for b in beacon_seq:
                if b == 1:
                    p_db0.append(db0_path2[b - 1])
                    path_loss_coff.append(path_loss2[b - 1])
                else:
                    p_db0.append(db0_path1[b - 1])
                    path_loss_coff.append(path_loss1[b - 1])

    else:
        raise ValueError(f"未定義的 beacon 組合: {beacon_seq}")


    # 計算距離
    estimated_distances = []
    for db0, db3, path_loss in zip(p_db0, rssi_vals, path_loss_coff):
        result = (db0 - db3) / (10 * path_loss)
        result_pow = math.pow(10, result)
        estimated_distances.append(round(result_pow, 3))

    # 計算真實距離
    tp = test_points[idx - 1]
    actual_distances = []
    for beacon_id in beacon_seq:
        bx, by = beacon_positions[beacon_id]
        dist = math.sqrt((tp[0] - bx)**2 + (tp[1] - by)**2)
        actual_distances.append(round(dist, 3))

    # 三角定位推估位置
    p1 = beacon_positions[beacon_seq[0]]
    p2 = beacon_positions[beacon_seq[1]]
    p3 = beacon_positions[beacon_seq[2]]
    r1, r2, r3 = estimated_distances
    pred_x, pred_y = trilateration(p1, r1, p2, r2, p3, r3)

    # 計算誤差
    pos_err = round(math.sqrt((tp[0] - pred_x)**2 + (tp[1] - pred_y)**2), 3) if pred_x is not None else None

    # 儲存結果
    row = {
        'Test Point': f'T{idx}',
        'True_X': tp[0],
        'True_Y': tp[1],
        'Beacon Seq': beacon_seq,
        'RSSI': rssi_vals,
        'Estimated Distances': estimated_distances,
        'Actual Distances': actual_distances,
        'Pred_X': pred_x,
        'Pred_Y': pred_y,
        'Position Error': pos_err
    }
    results.append(row)

# 輸出為表格
df_result = pd.DataFrame(results)
#print(df_result[['Test Point', 'Beacon Seq', 'RSSI', 'Estimated Distances', 'Actual Distances', 'Pred_X', 'Pred_Y', 'Position Error']])
print(df_result[['Beacon Seq', 'Pred_X', 'Pred_Y', 'Position Error']])