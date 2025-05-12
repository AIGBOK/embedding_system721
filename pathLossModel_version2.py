import csv
import math

# 輸入你想要抓的點（依序對應每組資料）
target_points = ['4', '2_2', '2_1', '1', '3_1', '3_2']
csv_file = "C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0506\\0506_rssi_output.csv"
output_path = "C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0506\\pathLoss_output.csv"

#0430的測資
# target_points = ['4']
# csv_file = "C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0430\\0430_rssi_output.csv"
# distanceGroup = [1,2,4,8]

taget_length = len(target_points)  # 輸出: 6
point_numbers = [int(p.split('_')[0]) for p in target_points]

# 儲存提取結果
extracted_dbms = []

with open(csv_file, newline='', encoding='utf-8') as f:
    reader = list(csv.reader(f))
    rows = reader[1:]  # 去掉header

# 每組完整資料是20行
group_size = 20
distanceGroup_size = 5

extracted_dbms = []

for i, point_num in enumerate(point_numbers):
    if i >= taget_length:
        break

    start_index = i * group_size
    group = rows[start_index:start_index + group_size]

    dbm_group = []

    for j in range(4):  # d=1~4
        row_idx = j * distanceGroup_size + point_num
        row_to_extract = group[row_idx]
        dbm_value = float(row_to_extract[2])
        dbm_group.append(dbm_value)

    extracted_dbms.append(dbm_group)

#用result_db0來儲存做三角定位時，需要用到的數值
result_db0 = []
# 顯示結果
for idx, group in enumerate(extracted_dbms):
    print(f"Group {idx + 1}: {group}")
    result_db0.append(group[0])

# 開始做path loss model
averagePathLoss = []
for idx, group in enumerate(extracted_dbms):
    v1 = group[0]
    results = []
    distance = 2   #從distance = 2 開始計算path loss
    for v in group[1:]:   #計算每個distance 相對 1 的path loss
        power_db = v1 - v
        log_result = math.log10(distance)  # 或 math.log(ratio) 若要自然對數
        result = power_db/(10* log_result)
        results.append(result)
        distance += 1
    print(f"Group {idx + 1}: log10 ratios relative to first value = {results}")
    #針對每一組計算平均的path loss
    average = sum(results) / len(results)
    averagePathLoss.append(average)

print("average Path Loss:")
for idx, group in enumerate(averagePathLoss):
    print(f"Group {idx + 1} = {group}")

# 開始做path loss model
# for idx, group in enumerate(extracted_dbms):
#     v1 = group[0]
#     results = []
#     k = 1
#     for v in group[1:]:   #計算每個distance 相對 1 的path loss
#         power_db = v1 - v
#         log_result = math.log10(distanceGroup[k])  # 或 math.log(ratio) 若要自然對數
#         result = power_db/(10* log_result)
#         results.append(result)
#         k += 1
#     print(f"Group {idx + 1}: log10 ratios relative to first value = {results}")

#我要輸出db0跟path loss 係數，來做三角定位的計算
#we have result_db0 來儲存distance = 1，的dbm
#we have averagePathLoss 來儲存每一組的path loss
with open(output_path, "w", newline='', encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["db0"] + result_db0)  # 合併成一列寫出
    writer.writerow(["PathLossCoeff"] + averagePathLoss)

print(f"✅ 已儲存至：{output_path}")
