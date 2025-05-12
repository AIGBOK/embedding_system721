import csv

# 修改成你的檔案路徑
input_csv = "C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0506\\0506_rssi_output.csv"

parsed_results = []

with open(input_csv, newline='', encoding='utf-8') as f:
    reader = csv.reader(f)
    next(reader)  # 跳過 header

    current_group = {}
    for row in reader:
        if not row or not row[0]:
            continue

        # 如果這行是時間範圍
        if row[0].lower().startswith("time"):
            # 儲存前一組
            if current_group:
                parsed_results.append(current_group)
            # 開始新一組
            current_group = {
                "start_time": row[1],
                "end_time": row[2],
                "rows": {}
            }

        # 否則就是 row1~row4 的資料
        else:
            label = row[0]
            try:
                rssi_mw = float(row[1])
                rssi_dbm = float(row[2])
            except ValueError:
                rssi_mw = None
                rssi_dbm = None
            current_group["rows"][label] = {
                "rssi_mw": rssi_mw,
                "rssi_dbm": rssi_dbm
            }

    # 加入最後一組
    if current_group:
        parsed_results.append(current_group)

# 輸出檢查（可省略）
for group in parsed_results:
    print(f"時間範圍：{group['start_time']} ~ {group['end_time']}")
    for row_name, values in group['rows'].items():
        print(f"  {row_name} - 平均RSSI: {values['rssi_mw']} mW, {values['rssi_dbm']} dBm")
