import csv
from datetime import datetime
import math
import numpy as np
from scipy.stats import linregress

data_list = []

file_path = "C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0527\\0527_major2.csv"
output_path = "C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0527\\fingerPrinting0527_ReadWrite.csv"

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
    ("10:46:03", "10:46:13"),  #point 0-1 
    ("10:46:46", "10:46:56"),  #0-2
    ("10:47:10", "10:47:20"),  #0-3 
    ("10:47:40", "10:47:50"),  #point 1-1 
    ("10:47:56", "10:48:06"),  #1-2
    ("10:48:11", "10:48:21"),  #1-3 
    ("10:49:40", "10:49:50"),  #point 2-1 
    ("10:49:56", "10:50:06"),  #2-2
    ("10:50:10", "10:50:20"),  #2-3 
    ("10:50:50", "10:51:00"),  #point 3-1 
    ("10:51:05", "10:51:15"),  #3-2
    ("10:51:19", "10:51:29"),  #3-3 
    ("10:51:48", "10:51:58"),  #point 4-1 
    ("10:52:01", "10:52:11"),  #4-2
    ("10:52:15", "10:52:25"),  #4-3 
    ("10:52:43", "10:52:53"),  #point 5-1 
    ("10:52:56", "10:53:06"),  #5-2
    ("10:53:10", "10:53:20"),  #5-3 
    ("10:53:28", "10:53:38"),  #point 6-1 
    ("10:53:52", "10:54:02"),  #6-2
    ("10:54:14", "10:54:24"),  #6-3 
    ("10:54:35", "10:54:45"),  #point 7-1 
    ("10:54:55", "10:55:05"),  #7-2
    ("10:55:11", "10:55:21"),  #7-3 
    ("10:55:39", "10:55:49"),  #point 8-1 
    ("10:56:10", "10:56:20"),  #8-2
    ("10:56:35", "10:56:45"),  #8-3 
    ("10:57:05", "10:57:15"),  #point 9-1 
    ("10:57:26", "10:57:36"),  #9-2
    ("10:57:45", "10:57:55"),  #9-3 
    ("10:58:19", "10:58:29"),  #point 10-1 
    ("10:58:33", "10:58:43"),  #10-2
    ("10:58:47", "10:58:57"),  #10-3 
    ("10:59:03", "10:59:13"),  #point 11-1 
    ("10:59:16", "10:59:26"),  #11-2
    ("10:59:30", "10:59:40"),  #11-3 
    ("11:00:09", "11:00:19"),  #point 12-1 
    ("11:00:39", "11:00:49"),  #12-2
    ("11:02:22", "11:02:32"),  #12-3 
    ("11:02:58", "11:03:08"),  #point 13-1 
    ("11:03:15", "11:03:25"),  #13-2
    ("11:03:29", "11:03:39"),  #13-3 
    ("11:04:00", "11:04:10"),  #point 14-1 
    ("11:04:20", "11:04:30"),  #14-2
    ("11:04:46", "11:04:56"),  #14-3 
    ("11:05:05", "11:05:15"),  #point 15-1 
    ("11:05:19", "11:05:29"),  #15-2
    ("11:05:32", "11:05:42"),  #15-3 
    ("11:05:55", "11:06:05"),  #point 16-1 
    ("11:06:09", "11:06:19"),  #16-2
    ("11:06:23", "11:06:33"),  #16-3     
    ("11:06:43", "11:06:53"),  #point 17-1 
    ("11:06:57", "11:07:07"),  #17-2
    ("11:07:13", "11:07:23"),  #17-3 
    ("11:07:44", "11:07:54"),  #point 18-1 
    ("11:08:04", "11:08:14"),  #18-2
    ("11:08:50", "11:09:00"),  #18-3 
    ("11:09:55", "11:10:05"),  #point 19-1 
    ("11:10:12", "11:10:22"),  #19-2
    ("11:10:26", "11:10:36"),  #19-3 
    ("11:10:40", "11:10:50"),  #point 20-1 
    ("11:11:10", "11:11:20"),  #20-2
    ("11:11:23", "11:11:33"),  #20-3 
    ("11:11:47", "11:11:57"),  #point 21-1 
    ("11:12:07", "11:12:17"),  #21-2
    ("11:12:20", "11:12:30"),  #21-3 
    ("11:12:52", "11:13:02"),  #point 22-1 
    ("11:13:16", "11:13:26"),  #22-2
    ("11:13:30", "11:13:40"),  #22-3 
    ("11:13:48", "11:13:58"),  #point 23-1 
    ("11:14:10", "11:14:20"),  #23-2
    ("11:14:27", "11:14:37"),  #23-3 
    ("11:17:00", "11:17:10"),  #point 24-1 
    ("11:17:18", "11:17:28"),  #24-2
    ("11:17:40", "11:17:50"),  #24-3 
    ("11:17:59", "11:18:09"),  #24-4
    ("11:18:12", "11:18:22"),  #24-5
    ("11:18:30", "11:18:40"),  #point 25-1 
    ("11:18:45", "11:18:55"),  #25-2
    ("11:19:00", "11:19:10"),  #25-3 
    ("11:19:15", "11:19:25"),  #25-4
    ("11:19:29", "11:19:39"),  #25-5
    ("11:20:15", "11:20:25"),  #point 26-1 
    ("11:20:32", "11:20:42"),  #26-2
    ("11:21:49", "11:21:59"),  #26-3 
    ("11:22:08", "11:22:18"),  #26-4
    ("11:22:22", "11:22:32"),  #26-5
    ("11:22:42", "11:22:52"),  #point 27-1 
    ("11:22:55", "11:23:05"),  #27-2
    ("11:23:08", "11:23:18"),  #27-3 
    ("11:23:27", "11:23:37"),  #27-4
    ("11:23:47", "11:23:57"),  #27-5
    ("11:24:04", "11:24:14"),  #point 28-1 
    ("11:24:16", "11:24:26"),  #28-2
    ("11:24:32", "11:24:42"),  #28-3 
    ("11:24:48", "11:24:58"),  #28-4
    ("11:25:01", "11:25:11"),  #28-5
    ("11:27:13", "11:27:23"),  #point 29-1 
    ("11:27:28", "11:27:38"),  #29-2
    ("11:27:47", "11:27:57"),  #29-3 
    ("11:28:00", "11:28:10"),  #29-4
    ("11:29:00", "11:29:10")   #29-5

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
            output_rows.append([f"row{row_idx + 1}", 0, -80])   #這裡原本是no information  預設最差是-80 db
            print(f"start time: {start_time}, end time: {end_time}, row_idx: {row_idx + 1}")

# 第四部分：寫入CSV檔案
with open(output_path, "w", newline='', encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerows(output_rows)

print("✅ 已成功輸出到：", output_path)