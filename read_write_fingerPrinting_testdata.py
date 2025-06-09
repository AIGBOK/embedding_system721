import csv
from datetime import datetime
import math
import numpy as np
from scipy.stats import linregress

data_list = []

file_path = "C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0527\\0527_major2.csv"
output_path = "C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0527\\fingerPrinting0527_testpoint.csv"

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
                    power_mW = 10 ** (rssi_db / 10)  #轉數值
                    time = row[i + 1]
                    row_dict[time] = power_mW
            except (ValueError, IndexError):
                continue
        data_list.append(row_dict)


# 第二部分：定義時間範圍
time_ranges = [
    ("11:32:54", "11:33:04"),  #point 1
    ("11:33:57", "11:34:07"),  #2
    ("11:35:30", "11:35:40"),  #3 
    ("11:36:27", "11:36:37"),  #point 4
    ("11:37:22", "11:37:32"),  #5
    ("11:38:11", "11:38:21"),  #6 
    ("11:39:20", "11:39:30")   #point 7 

]

time_ranges_dt = [
    (datetime.strptime(start, "%H:%M:%S"), datetime.strptime(end, "%H:%M:%S"))
    for start, end in time_ranges
]

# 第三部分：建立輸出表格格式
output_rows = [["minor", "average rssi(mW)", "dBm"]]

def percentile_trimmed(data, low=10, high=90):
    low_val = np.percentile(data, low)
    high_val = np.percentile(data, high)
    trimmed = [x for x in data if low_val <= x <= high_val]
    return trimmed, sum(trimmed) / len(trimmed)

for start_time, end_time in time_ranges_dt:
    start_str = start_time.strftime("%H:%M:%S")
    end_str = end_time.strftime("%H:%M:%S")
    output_rows.append(["time range", start_str, end_str])

    for row_idx, row_dict in enumerate(data_list):
        total_rssi = []

        for time_str, rssi in row_dict.items():
            try:
                time_obj = datetime.strptime(time_str, "%H:%M:%S")
                if start_time <= time_obj < end_time:
                    total_rssi.append(rssi)
            except ValueError:
                continue

        if  total_rssi:  # 如果陣列裡面有值
            if len(total_rssi) >= 5:
                trimmed, avg_rssi = percentile_trimmed(total_rssi, 10, 90)   # 經過trim 
                avg_rssi_db = 10 * math.log10(avg_rssi) #不用數值轉db了   
                output_rows.append([f"row{row_idx + 1}", f"{avg_rssi:.6e}", f"{avg_rssi_db:.2f}"])
            else:
                avg_rssi = sum(total_rssi) / len(total_rssi)
                avg_rssi_db = 10 * math.log10(avg_rssi) #不用數值轉db了   
                output_rows.append([f"row{row_idx + 1}", f"{avg_rssi:.6e}", f"{avg_rssi_db:.2f}"])
            
        else:
            output_rows.append([f"row{row_idx + 1}", 0, -100])   #這裡原本是no information  預設最差是-100 db
            print(f"start time: {start_time}, end time: {end_time}, row_idx: {row_idx + 1}")

# 第四部分：寫入CSV檔案
with open(output_path, "w", newline='', encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerows(output_rows)

print("✅ 已成功輸出到：", output_path)