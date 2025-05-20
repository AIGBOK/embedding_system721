import csv
from collections import defaultdict

# 輸入檔案
input_file = 'C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0520\\beacon_20250520_115051.csv'

# 輸出檔案前綴（會加上 major 的值）
output_prefix = 'C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0520\\0520_major'

# 讀取 CSV 檔案
with open(input_file, newline='', encoding='utf-8') as f:
    reader = list(csv.reader(f))
    header = reader[0]
    data_rows = reader[1:]

    # 找出 Major 和 Minor 的 index
    major_index = header.index('Major')
    minor_index = header.index('Minor')

    # 用 dictionary 分組資料
    grouped_data = defaultdict(list)
    for row in data_rows:
        major_value = int(row[major_index])
        grouped_data[major_value].append(row)

# 寫出每個 Major 的檔案
for major, rows in grouped_data.items():
    # 每組內部按照 Minor 排序
    sorted_rows = sorted(rows, key=lambda r: int(r[minor_index]))
    
    # 檔名格式，例如：0514_major1.csv
    output_file = f'{output_prefix}{major}.csv'

    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(sorted_rows)
