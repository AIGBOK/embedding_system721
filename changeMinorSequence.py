import csv

#0430的測資
input_file = 'C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0430\\beacon_20250430_111838.csv'    # 換成你的實際檔案名稱
output_file = 'C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0430\\0430final.csv'

#0506的測資
# input_file = 'C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0506\\beacon_20250506_115613.csv'    # 換成你的實際檔案名稱
# output_file = 'C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0506\\0506final.csv'

# 讀取 csv 檔案
with open(input_file, newline='', encoding='utf-8') as f:
    reader = list(csv.reader(f))
    header = reader[0]                     # 第一列是標題
    data_rows = reader[1:]                 # 其餘為資料列

    # 把每一列的 Minor 欄位轉成整數來排序
    minor_index = header.index('Minor')   # 找出 Minor 欄位的位置
    data_rows.sort(key=lambda row: int(row[minor_index]))

# 寫入排序後的檔案
with open(output_file, 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(header)       # 寫入標題
    writer.writerows(data_rows)   # 寫入排序後資料列
