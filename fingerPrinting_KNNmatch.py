import pandas as pd
import numpy as np

def load_and_process_csv(csv_path):
    df = pd.read_csv(csv_path, header=None)
    time_indices = df.index[df[0] == "time range"].tolist()

    diff_vectors = []
    labels = []

    for i, idx in enumerate(time_indices):
        group = df.iloc[idx+1:idx+9]
        try:
            rssi_values = group[2].astype(float).values
            diff_vectors.append(rssi_values)
            labels.append(f"group{i+1}")
        except:
            continue

    return np.array(diff_vectors), np.array(labels)

def compute_position(group_number, y_vector):
    if group_number > 72:
        x = (((group_number - 73) // 5 ) + 24) * 0.6
        y_index = ((group_number - 73) % 5)
        y = y_vector[y_index]
    else:
        x = (((group_number - 1) // 3 )) * 0.6
        y_index = ((group_number - 1) % 3)
        y = y_vector[y_index]
    return x, y

def knn_match(test_vectors, database_vectors, database_labels, k=3):
    results = []
    y_vector = [0.54, 1.22, 1.88, 2.57, 3.2]

    for i, test_vec in enumerate(test_vectors):
        distances = np.linalg.norm(database_vectors - test_vec, axis=1)
        nearest_indices = np.argsort(distances)[:k]

        positions = []
        for idx in nearest_indices:
            group_number = idx + 1
            x, y = compute_position(group_number, y_vector)
            positions.append((x, y))

        # 計算平均位置
        xs, ys = zip(*positions)
        avg_x = round(np.mean(xs), 2)
        avg_y = round(np.mean(ys), 2)

        results.append({
            "TestGroup": f"test{i+1}",
            "x": avg_x,
            "y": avg_y,
            "MatchedGroups": [database_labels[idx] for idx in nearest_indices],
            "Distances": [round(distances[idx], 2) for idx in nearest_indices],
            **{f"rssi{j+1}": val for j, val in enumerate(test_vec)}
        })

    return pd.DataFrame(results)

if __name__ == "__main__":
    db_csv_file = "C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0527\\fingerPrinting0527_ReadWrite.csv"
    db_vectors, db_labels = load_and_process_csv(db_csv_file)

    test_csv_file = "C:\\Users\\chouy\\Desktop\\embedding_system\\Documents0527\\fingerPrinting0527_testpoint.csv"
    test_vectors, _ = load_and_process_csv(test_csv_file)

    result_df = knn_match(test_vectors, db_vectors, db_labels, k=3)

    print(result_df)
    result_df.to_csv("test_result_knn.csv", index=False)
