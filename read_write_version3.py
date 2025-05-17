import csv
from datetime import datetime
import math
import numpy as np
from scipy.stats import linregress

data_list = []

file_path = "C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0514\\0514final.csv"
output_path = "C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0514\\pathLoss0514_output.csv"

# 第一部分：讀取資料
with open(file_path, "r", encoding="utf-8") as f:
    reader = csv.reader(f)
    next(reader)  # 跳過 header

    for row in reader:
        if not row:
            continue
        row_dict = {}
        for i in range(2, len(row) - 1, 3):
            try:
                rssi_db = int(row[i])
                if( rssi_db >= -10):  #這裡要判斷有沒有rssi = 0 的值，要刪掉才不會影響計算
                    continue
                else:
                    #power_mW = 10 ** (rssi_db / 10)  #不用轉數值了
                    time = row[i + 1]
                    row_dict[time] = rssi_db
            except (ValueError, IndexError):
                continue
        data_list.append(row_dict)


# 第二部分：定義時間範圍
time_ranges = [
    ("11:30:00", "11:30:10"),  ##point 1 d=1 
    ("11:31:03", "11:31:13"),  #d=2
    ("11:32:00", "11:32:10"),  #d=3 
    ("11:32:57", "11:33:07"),  #d=4   
    ("11:21:16", "11:21:26"),  ##point 2 d=1 
    ("11:21:41", "11:21:51"),  #d=2
    ("11:22:40", "11:22:50"),  #d=3
    ("11:23:40", "11:23:50"),  #d=4
    ("11:25:04", "11:25:14"),  ##point 3 d=1 
    ("11:26:04", "11:26:14"),  #d=2
    ("11:27:04", "11:27:14"),  #d=3
    ("11:28:45", "11:28:55"),  #d=4
    ("11:13:20", "11:13:30"),  ##point 4 d=1
    ("11:14:21", "11:14:31"),  #d=2
    ("11:16:49", "11:16:59"),  #d=3
    ("11:18:20", "11:18:30"),  #d=4
    ("11:37:23", "11:37:33"),
    ("11:35:20", "11:35:30"),

]

time_ranges_dt = [
    (datetime.strptime(start, "%H:%M:%S"), datetime.strptime(end, "%H:%M:%S"))
    for start, end in time_ranges
]
group_size = 4 #每4個一組
grouped_ranges = [time_ranges_dt[(i*group_size):(i*group_size)+group_size] for i in range(0, len(time_ranges_dt) // group_size, 1)]


# 第三部分：建立輸出表格格式
# 這個function 是做trim，也就是把前後幾筆資料刪掉，減少極值造成的影響
def percentile_trimmed(data, low=10, high=90):
    low_val = np.percentile(data, low)
    high_val = np.percentile(data, high)
    trimmed = [x for x in data if low_val <= x <= high_val]
    return trimmed, sum(trimmed) / len(trimmed)

#用來抓距離，做regression用的
distance = [1,2,3,4]
result_db0 = []
averagePathLoss = []  
for row_idx, row_dict in enumerate(data_list):
    group = grouped_ranges[row_idx]  # 這樣就取得一組，裡面有 4 個 (start, end) tuple
    valid_rssi = []  #用來儲存最後用於regression的資料
    valid_logd = []
    count = 0
    for start_time, end_time in group:  #總共會有四個distance，做四次迴圈
        start_str = start_time.strftime("%H:%M:%S")
        end_str = end_time.strftime("%H:%M:%S")
        rssi_origin = []
        for time_str, rssi in row_dict.items():
            try:
                time_obj = datetime.strptime(time_str, "%H:%M:%S")
                if start_time <= time_obj < end_time:
                    rssi_origin.append(rssi)
            except ValueError:
                continue
        if rssi_origin: #判斷是否為空
            trimmed, avg_rssi = percentile_trimmed(rssi_origin, 10, 90)   # 經過trim          
            #avg_rssi_db = 10 * math.log10(avg_rssi) #不用數值轉db了
            valid_rssi.extend(trimmed)
            valid_logd.extend([np.log10(distance[count])] * len(trimmed))
        else:
            print([f"row{row_idx + 1}", "No information", "No information"])
        count += 1
    slope, intercept, _, _, _ = linregress(valid_logd, valid_rssi)
    P0 = intercept
    n = -slope / 10 
    # 寫入csv檔案
    result_db0.append(P0)
    averagePathLoss.append(n)
    print(f"📦 第 {row_idx + 1} 組 Path Loss 模型參數：")
    print(f"  P0 = {P0:.2f} dBm")
    print(f"  n  = {n:.2f}\n")   
# 第四部分：寫入CSV檔案    
with open(output_path, "w", newline='', encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["db0"] + result_db0)  # 合併成一列寫出
    writer.writerow(["PathLossCoeff"] + averagePathLoss)

print(f"✅ 已儲存至：{output_path}")
