import csv
from datetime import datetime
import math

data_list = []

file_path = "C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0514\\0514final.csv"
output_path = "C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0514\\0514_rssi_testoutput.csv"

# 第一部分：讀取資料
# with open(file_path, "r", encoding="utf-8") as f:
#     reader = csv.reader(f)
#     next(reader)

#     for row in reader:
#         if not row:
#             continue

#         row_dict = {}
#         for i in range(2, len(row) - 1, 2):
#             try:
#                 rssi_db = int(row[i])
#                 power_mW = 10 ** (rssi_db / 10)
#                 time = row[i + 1]
#                 row_dict[time] = power_mW
#             except (ValueError, IndexError):
#                 continue
#         data_list.append(row_dict)
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
                if( rssi_db >= -10):
                    continue
                else:
                    power_mW = 10 ** (rssi_db / 10)
                    time = row[i + 1]
                    row_dict[time] = power_mW
            except (ValueError, IndexError):
                continue
        data_list.append(row_dict)


# 第二部分：定義時間範圍
# time_ranges = [
#     ("11:10:40", "11:11:40"),
#     ("11:11:40", "11:12:40"),
#     ("11:12:40", "11:13:40"),
#     ("11:13:40", "11:14:00"),
#     ("11:14:00", "11:15:00"),
#     ("11:15:20", "11:16:20"),
#     ("11:16:30", "11:17:30")
# ]
time_ranges = [
    ("11:30:00", "11:30:10"),  ##point 1 d=1 
    ("11:31:03", "11:31:13"),  #d=2
    ("11:32:00", "11:32:10"),  #d=3 
    ("11:32:57", "11:33:07"),  #d=4   
    ("11:21:16", "11:21:26"),  
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
    ("11:35:20", "11:35:30")

]

time_ranges_dt = [
    (datetime.strptime(start, "%H:%M:%S"), datetime.strptime(end, "%H:%M:%S"))
    for start, end in time_ranges
]

# 第三部分：建立輸出表格格式
output_rows = [["minor", "average rssi(mW)", "dBm"]]

for start_time, end_time in time_ranges_dt:
    start_str = start_time.strftime("%H:%M:%S")
    end_str = end_time.strftime("%H:%M:%S")
    output_rows.append(["time range", start_str, end_str])

    for row_idx, row_dict in enumerate(data_list):
        total_rssi = 0
        count = 0

        for time_str, rssi in row_dict.items():
            try:
                time_obj = datetime.strptime(time_str, "%H:%M:%S")
                if start_time <= time_obj < end_time:
                    total_rssi += rssi
                    count += 1
            except ValueError:
                continue

        if count > 0:
            avg_rssi = total_rssi / count
            avg_rssi_db = 10 * math.log10(avg_rssi)
            output_rows.append([f"row{row_idx + 1}", f"{avg_rssi:.6e}", f"{avg_rssi_db:.2f}"])
        else:
            output_rows.append([f"row{row_idx + 1}", "No information", "No information"])

# 第四部分：寫入CSV檔案
with open(output_path, "w", newline='', encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerows(output_rows)

print("✅ 已成功輸出到：", output_path)
