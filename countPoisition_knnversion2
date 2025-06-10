import UIKit
import CoreLocation
import CoreMotion

// MARK: - Data Structures
struct BeaconData {
    let rssi: Int
    let timestamp: Date
    let yaw: Double
}

struct PositionResult {
    let testGroup: String
    let x: Double
    let y: Double
    let matchedGroups: [String]
    let distances: [Double]
    let rssiValues: [Double]
}

class ViewController: UIViewController, CLLocationManagerDelegate {
    // MARK: - Properties
    var locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    var currentYaw: Double = 0.0
    var isRecording = false
    var beaconRSSLog: [String: [BeaconData]] = [:]

    // MARK: - Outlets
    @IBOutlet weak var rangingResultTextView: UITextView!
    @IBOutlet weak var monitorResultTextView: UITextView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var exportButton: UIButton!

    // MARK: - Constants
    let uuid = "77C99B62-88FC-4C78-B39C-D6FE06E76372"
    let identifier = "esd region"

    // MARK: - Constants for KNN Fingerprinting
    let yVector: [Double] = [0.54, 1.22, 1.88, 2.57, 3.2]

    // **請保留你原本的 dbVectors 與 dbLabels 陣列，這裡省略：**
    let dbVectors: [[Double]] = [
            [-55.29, -60.2,  -60.18, -64.47, -68.33, -69.11, -75.55, -66.67],
            [-41.35, -65.31, -55.96, -70.03, -65.42, -64.63, -77.38, -79.42],
            [-44.76, -61.21, -62.16, -77.54, -69.48, -70.14, -78.42, -75.2 ],
            [-50.92, -57.54, -57.37, -68.6,  -64.78, -63.92, -77.56, -71.51],
            [-50.05, -54.52, -55.92, -71.45, -66.55, -66.96, -79.0,  -73.36],
            [-53.12, -54.4,  -54.91, -71.07, -59.1,  -66.23, -74.75, -74.77],
            [-61.02, -57.61, -57.23, -74.51, -63.66, -67.94, -80.23, -76.94],
            [-55.06, -58.83, -55.13, -76.4,  -60.78, -65.91, -74.05, -69.16],
            [-53.59, -48.67, -52.29, -74.24, -62.55, -65.47, -76.94, -77.29],
            [-53.62, -46.2,  -50.62, -71.62, -62.95, -62.23, -73.62, -79.64],
            [-56.88, -46.24, -57.31, -72.39, -59.35, -66.59, -78.5,  -74.38],
            [-57.02, -42.78, -50.28, -64.96, -62.03, -61.43, -77.92, -74.94],
            [-59.56, -57.83, -51.72, -74.75, -60.37, -65.57, -75.79, -74.93],
            [-58.36, -53.73, -51.8,  -70.33, -62.22, -64.46, -74.2,  -72.55],
            [-59.23, -63.02, -51.65, -68.16, -56.19, -63.94, -75.34, -72.33],
            [-55.15, -49.94, -52.14, -73.95, -56.78, -71.72, -76.62, -77.81],
            [-59.65, -58.0,  -44.8,  -73.43, -61.4,  -67.88, -78.89, -70.7 ],
            [-62.8,  -57.18, -48.4,  -66.14, -60.25, -65.0,  -73.61, -72.29],
            [-60.9,  -54.02, -49.65, -69.71, -55.83, -63.1,  -81.64, -72.77],
            [-59.97, -60.18, -42.8,  -69.74, -55.21, -61.11, -78.09, -77.7 ],
            [-61.52, -54.98, -41.17, -67.08, -56.21, -63.24, -70.81, -71.47],
            [-59.96, -61.43, -41.11, -72.45, -56.47, -63.18, -75.32, -72.0 ],
            [-59.27, -60.84, -41.94, -66.18, -53.12, -60.78, -75.15, -74.0 ],
            [-60.48, -65.52, -44.73, -65.98, -55.79, -65.51, -72.09, -75.32],
            [-52.19, -56.42, -37.3,  -63.49, -56.93, -61.61, -71.71, -74.22],
            [-63.35, -64.34, -37.53, -66.68, -63.72, -60.06, -74.59, -74.26],
            [-64.35, -65.24, -38.67, -68.45, -53.53, -61.26, -68.36, -72.25],
            [-62.54, -63.62, -50.25, -65.21, -54.47, -61.22, -76.81, -74.72],
            [-68.11, -66.81, -45.63, -59.13, -51.74, -57.63, -79.32, -71.35],
            [-72.42, -65.3,  -44.28, -67.52, -56.78, -62.13, -71.55, -71.75],
            [-70.83, -62.83, -55.48, -67.91, -52.18, -61.36, -77.12, -72.21],
            [-70.19, -63.89, -48.4,  -63.69, -55.54, -62.02, -74.0,  -72.67],
            [-64.79, -65.9,  -48.79, -62.67, -56.05, -61.74, -70.75, -71.01],
            [-66.74, -62.43, -58.88, -61.07, -46.61, -57.95, -74.82, -72.26],
            [-73.59, -64.71, -53.07, -62.73, -51.4,  -60.6,  -75.55, -69.14],
            [-68.91, -70.77, -54.8,  -61.51, -51.95, -58.92, -72.88, -70.95],
            [-63.2,  -63.21, -54.84, -59.69, -54.96, -62.2,  -75.29, -75.5 ],
            [-61.76, -66.08, -50.13, -61.57, -52.57, -62.49, -72.51, -73.59],
            [-65.53, -66.34, -48.8,  -66.0,  -53.01, -63.04, -70.21, -73.4 ],
            [-69.29, -59.25, -53.47, -58.05, -53.28, -63.46, -76.57, -68.8 ],
            [-62.64, -63.73, -54.39, -55.91, -47.4,  -63.4,  -76.87, -71.77],
            [-62.81, -68.81, -55.14, -57.77, -48.47, -55.08, -71.66, -72.1 ],
            [-66.64, -64.26, -59.26, -52.11, -49.47, -62.63, -71.63, -72.14],
            [-68.16, -66.57, -53.62, -56.33, -45.5,  -56.74, -73.64, -68.49],
            [-63.47, -67.39, -52.17, -54.49, -43.5,  -56.83, -69.87, -74.38],
            [-65.7,  -66.38, -59.01, -49.22, -45.46, -52.46, -70.45, -69.97],
            [-64.53, -67.74, -56.27, -48.26, -43.8,  -52.07, -73.35, -72.42],
            [-68.42, -67.19, -54.33, -46.57, -43.78, -58.7,  -70.51, -70.91],
            [-65.61, -68.23, -59.14, -54.86, -39.0,  -49.16, -69.55, -66.9 ],
            [-66.61, -66.92, -58.8,  -47.57, -35.0,  -52.78, -64.65, -70.4 ],
            [-66.75, -69.1,  -54.81, -44.23, -36.45, -56.76, -64.35, -73.91],
            [-66.2,  -68.73, -59.28, -49.6,  -34.0,  -50.04, -74.23, -68.07],
            [-70.37, -73.45, -56.76, -48.03, -34.0,  -52.05, -67.87, -74.45],
            [-68.48, -70.31, -53.82, -55.42, -35.6,  -52.46, -63.49, -72.44],
            [-73.36, -73.11, -66.31, -54.76, -44.52, -46.83, -61.11, -68.51],
            [-68.6,  -67.86, -69.41, -60.27, -36.47, -47.43, -67.71, -69.36],
            [-72.39, -78.26, -64.67, -63.71, -41.0,  -51.67, -61.6,  -70.34],
            [-68.28, -71.26, -71.5,  -53.0,  -56.31, -44.48, -66.6,  -64.96],
            [-72.61, -71.78, -65.83, -64.7,  -43.68, -42.67, -62.62, -72.17],
            [-78.1,  -71.2,  -65.53, -65.1,  -42.0,  -44.92, -58.93, -64.95],
            [-74.45, -74.99, -67.73, -64.54, -57.51, -41.18, -59.13, -61.38],
            [-80.0,  -72.6,  -68.7,  -67.65, -53.18, -40.35, -59.12, -59.48],
            [-79.72, -76.3,  -73.67, -66.23, -47.42, -37.5,  -59.33, -64.73],
            [-78.0,  -75.41, -68.01, -71.32, -59.13, -40.15, -58.6,  -60.1 ],
            [-78.23, -74.81, -67.34, -68.62, -59.25, -36.5,  -58.12, -62.45],
            [-76.83, -73.45, -68.49, -71.66, -53.97, -33.39, -57.29, -60.94],
            [-80.0,  -79.47, -70.77, -72.83, -58.37, -41.8,  -55.66, -54.11],
            [-80.25, -77.64, -71.32, -74.35, -60.23, -40.05, -55.61, -56.98],
            [-75.03, -75.51, -71.52, -70.31, -57.42, -45.33, -56.57, -57.45],
            [-80.0,  -75.62, -70.42, -74.25, -54.42, -44.76, -52.95, -56.76],
            [-80.0,  -77.32, -75.08, -74.29, -62.63, -44.55, -58.02, -55.79],
            [-77.47, -73.32, -70.96, -70.02, -55.78, -51.77, -58.18, -53.96],
            [-78.27, -79.05, -71.25, -74.78, -64.38, -48.82, -51.23, -57.8 ],
            [-80.0,  -78.0,  -72.83, -76.89, -64.64, -53.12, -52.73, -57.45],
            [-77.31, -78.07, -70.03, -74.63, -62.12, -52.51, -53.06, -54.99],
            [-80.0,  -71.51, -73.81, -74.47, -57.65, -55.21, -56.04, -55.57],
            [-80.0,  -78.0,  -75.13, -76.54, -62.28, -58.62, -57.43, -56.49],
            [-80.0,  -76.5,  -71.86, -76.57, -68.33, -48.54, -53.65, -56.82],
            [-78.47, -76.22, -73.48, -76.15, -58.4,  -52.46, -51.31, -53.95],
            [-77.89, -77.31, -70.77, -78.93, -64.08, -57.24, -53.06, -55.04],
            [-80.0,  -75.85, -73.61, -71.18, -61.1,  -59.0,  -55.53, -54.85],
            [-78.0,  -76.39, -73.27, -78.78, -58.55, -57.1,  -56.05, -52.61],
            [-78.17, -78.04, -70.98, -73.13, -59.5,  -57.17, -58.03, -48.01],
            [-78.98, -80.0,  -70.94, -76.19, -59.99, -57.94, -60.57, -53.7 ],
            [-80.8,  -78.45, -69.84, -79.89, -62.59, -54.15, -61.74, -52.16],
            [-83.0,  -79.47, -70.81, -74.34, -63.29, -59.26, -58.31, -55.77],
            [-82.47, -73.66, -73.91, -82.0,  -62.69, -59.15, -61.31, -53.21],
            [-77.23, -78.63, -73.66, -78.36, -64.72, -56.82, -64.26, -51.5 ],
            [-82.47, -76.48, -74.56, -77.54, -66.71, -56.92, -64.93, -50.67],
            [-79.22, -78.23, -71.99, -75.36, -63.34, -60.35, -64.35, -48.0 ],
            [-79.55, -78.05, -70.34, -78.89, -62.48, -55.55, -60.6,  -45.88],
            [-79.25, -78.47, -70.95, -77.17, -58.74, -57.04, -61.32, -42.72],
            [-79.59, -77.09, -75.1,  -76.96, -65.2,  -55.98, -66.81, -53.23],
            [-78.47, -79.28, -76.5,  -78.97, -64.71, -54.96, -58.68, -51.2 ]
        ]


        let dbLabels: [String] = [
            "group1", "group2", "group3", "group4", "group5", "group6",
            "group7", "group8", "group9", "group10", "group11", "group12",
            "group13", "group14", "group15", "group16", "group17", "group18",
            "group19", "group20", "group21", "group22", "group23", "group24",
            "group25", "group26", "group27", "group28", "group29", "group30",
            "group31", "group32", "group33", "group34", "group35", "group36",
            "group37", "group38", "group39", "group40", "group41", "group42",
            "group43", "group44", "group45", "group46", "group47", "group48",
            "group49", "group50", "group51", "group52", "group53", "group54",
            "group55", "group56", "group57", "group58", "group59", "group60",
            "group61", "group62", "group63", "group64", "group65", "group66",
            "group67", "group68", "group69", "group70", "group71", "group72",
            "group73", "group74", "group75", "group76", "group77", "group78",
            "group79", "group80", "group81", "group82", "group83", "group84",
            "group85", "group86", "group87", "group88", "group89", "group90",
            "group91", "group92", "group93", "group94", "group95", "group96",
            "group97", "group98", "group99", "group100", "group101", "group102"
        ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationManager()
        setupMotionManager()
        setupUI()
    }

    // MARK: - Setup
    func setupLocationManager() {
        locationManager.delegate = self
        if #available(iOS 14, *) {
            let currentStatus = locationManager.authorizationStatus
            if currentStatus != .authorizedAlways {
                locationManager.requestAlwaysAuthorization()
            }
        } else {
            let currentStatus = CLLocationManager.authorizationStatus()
            if currentStatus != .authorizedAlways {
                locationManager.requestAlwaysAuthorization()
            }
        }
        let constraint = CLBeaconIdentityConstraint(uuid: UUID(uuidString: uuid)!)
        locationManager.startRangingBeacons(satisfying: constraint)
    }

    func setupMotionManager() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.2
        motionManager.startDeviceMotionUpdates()
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            if let att = self?.motionManager.deviceMotion?.attitude {
                self?.currentYaw = att.yaw * 180 / .pi
            }
        }
    }

    func setupUI() {
        monitorResultTextView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        monitorResultTextView.isEditable = false
        monitorResultTextView.isSelectable = true
        startButton.setTitle("Start Recording", for: .normal)
        exportButton.setTitle("Calculate Position", for: .normal)
        exportButton.isEnabled = false
    }

    // MARK: - Beacon Callback（不動，clamp 邏輯留在這）
    func locationManager(_ manager: CLLocationManager,
                         didRangeBeacons beacons: [CLBeacon],
                         in region: CLBeaconRegion) {
        guard isRecording else { return }

        var newText = ""
        for beacon in beacons {
            let key = "\(beacon.major)-\(beacon.minor)"
            if beaconRSSLog[key] == nil {
                beaconRSSLog[key] = []
            }

            // clamp：若 RSSI > -10，就當成 -90
            let rawRSSI = beacon.rssi
            let sanitizedRSSI = rawRSSI > -10 ? -90 : rawRSSI

            let data = BeaconData(
                rssi: sanitizedRSSI,
                timestamp: Date(),
                yaw: currentYaw
            )
            beaconRSSLog[key]!.append(data)

            let yawStr = String(format: "%.2f", currentYaw)
            newText +=
                "Major: \(beacon.major)  Minor: \(beacon.minor)\n" +
                "RSSI: \(sanitizedRSSI)  Yaw: \(yawStr)°\n\n"
        }

        DispatchQueue.main.async {
            self.rangingResultTextView.text = newText
        }
    }


    // MARK: - Actions
    @IBAction func startButtonTapped(_ sender: UIButton) {
        isRecording.toggle()
        if isRecording {
            beaconRSSLog.removeAll()
            startButton.setTitle("Stop Recording", for: .normal)
            exportButton.isEnabled = false
            monitorResultTextView.text = "Recording..."
        } else {
            startButton.setTitle("Start Recording", for: .normal)
            exportButton.isEnabled = true
            monitorResultTextView.text = "Recording stopped. Ready to calculate."
        }
    }

    @IBAction func exportButtonTapped(_ sender: UIButton) {
        calculatePosition()
    }

    // MARK: - Position Calculation (KNN Fingerprinting)
    func calculatePosition() {
        // 1. 先從 beaconRSSLog 過濾出 major = 2
        let major2Logs = beaconRSSLog
            .filter { key, _ in Int(key.split(separator: "-")[0]) == 2 }

        guard !major2Logs.isEmpty else {
            monitorResultTextView.text = "major=2 沒有任何資料"
            return
        }

        // 2. 產生固定長度 8 的 avgVector，minor 1…8，缺就填 -90
        let avgVector: [Double] = (1...8).map { minor in
            let key = "2-\(minor)"
            if let recs = major2Logs[key], !recs.isEmpty {
                // 再 clamp 一次保險
                let sanitized = recs.map { Double($0.rssi > -10 ? -90 : $0.rssi) }
                return sanitized.reduce(0, +) / Double(sanitized.count)
            } else {
                // 該 minor 這個時段沒收到，填 -90
                return -90.0
            }
        }

        // 3. 用這個 avgVector 做 KNN fingerprinting
        let results = knnMatch(testVectors: [avgVector], k: 3)
        guard let first = results.first else {
            monitorResultTextView.text = "KNN 回傳空結果"
            return
        }

        // 4. 顯示結果
        var txt = "=== Major=2 Fingerprint KNN ===\n"
        txt += "TestGroup: \(first.testGroup)\n"
        txt += String(format: "Estimated Position: x=%.2f, y=%.2f\n", first.x, first.y)
        txt += "Matched DB Groups: " + first.matchedGroups.joined(separator: ", ")
        monitorResultTextView.text = txt
    }

    // MARK: - CSV I/O Helpers
    /// Saves the recorded beacon RSSI data to a CSV file,
    /// 只抓 major=filterMajor，並依 minor 升冪排序。
    func saveBeaconDataToCSV(onlyMajor filterMajor: Int? = nil) -> URL {
        // 1. 檔名與路徑
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let filename = "beacon_data_\(formatter.string(from: Date())).csv"
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = docs.appendingPathComponent(filename)

        // 2. CSV 標頭
        var csv = "Major,Minor"
        for i in 1...8 { csv += ",RSSI\(i),Time\(i),Yaw\(i)" }
        csv += "\n"

        // 3. 依 filterMajor 與 minor 排序
        let keysToWrite: [String]
        if let fm = filterMajor {
            let filtered = beaconRSSLog.filter { k, _ in
                Int(k.split(separator: "-")[0]) == fm
            }
            keysToWrite = filtered.keys.sorted {
                let m1 = Int($0.split(separator: "-")[1])!
                let m2 = Int($1.split(separator: "-")[1])!
                return m1 < m2
            }
        } else {
            keysToWrite = beaconRSSLog.keys.sorted {
                let p1 = $0.split(separator: "-").map { Int($0)! }
                let p2 = $1.split(separator: "-").map { Int($0)! }
                if p1[0] != p2[0] { return p1[0] < p2[0] }
                return p1[1] < p2[1]
            }
        }

        // 4. 寫入每一行
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm:ss"
        for key in keysToWrite {
            let parts = key.split(separator: "-")
            guard let major = Int(parts[0]), let minor = Int(parts[1]),
                  let records = beaconRSSLog[key], records.count >= 8
            else { continue }

            let last8 = records.suffix(8)
            var line = "\(major),\(minor)"
            for entry in last8 {
                let t = timeFmt.string(from: entry.timestamp)
                let y = String(format: "%.2f", entry.yaw)
                line += ",\(entry.rssi),\(t),\(y)"
            }
            csv += line + "\n"
        }

        // 5. 輸出檔案
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ Saved to \(fileURL.lastPathComponent)")
        } catch {
            print("❌ Save failed: \(error)")
        }
        return fileURL
    }

    func loadAndProcessCSV(at url: URL) -> ([[Double]], [String]) {
        guard let raw = try? String(contentsOf: url) else { return ([], []) }
        let lines = raw.components(separatedBy: "\n")
        var diff: [[Double]] = [], labels: [String] = []
        for row in lines {
            let cols = row.split(separator: ",")
            if cols.count >= 10,
               Double(cols[0]) != nil, Double(cols[1]) != nil
            {
                let vec = cols[2..<10].compactMap { Double($0) }
                if vec.count == 8 {
                    diff.append(vec)
                    labels.append("test\(diff.count)")
                }
            }
        }
        return (diff, labels)
    }

    func computePosition(groupNumber: Int) -> (Double, Double) {
        if groupNumber > 72 {
            let x = (Double((groupNumber - 73) / 5) + 24) * 0.6
            let yi = (groupNumber - 73) % 5
            return (x, yVector[yi])
        } else {
            let x = Double((groupNumber - 1) / 3) * 0.6
            let yi = (groupNumber - 1) % 3
            return (x, yVector[yi])
        }
    }

    func knnMatch(testVectors: [[Double]], k: Int) -> [PositionResult] {
        var results: [PositionResult] = []
        for (i, test) in testVectors.enumerated() {
            let dists = dbVectors.map { db in
                zip(db, test).map { (a, b) in (a-b)*(a-b) }.reduce(0,+).squareRoot()
            }
            let top = dists.enumerated().sorted { $0.1 < $1.1 }.prefix(k)
            var xs: [Double] = [], ys: [Double] = []
            var matched: [String] = [], ds: [Double] = []
            for (idx, dist) in top {
                let (x, y) = computePosition(groupNumber: idx+1)
                xs.append(x); ys.append(y); matched.append(dbLabels[idx]); ds.append(dist)
            }
            results.append(
                PositionResult(
                    testGroup: "test\(i+1)",
                    x: xs.reduce(0, +)/Double(xs.count),
                    y: ys.reduce(0, +)/Double(ys.count),
                    matchedGroups: matched,
                    distances: ds,
                    rssiValues: test
                )
            )
        }
        return results
    }

    // MARK: - Utility to compute average RSSI (你原本的 calculateAverageRSSI)
    func calculateAverageRSSI() -> [String: Double] {
        var avg: [String: Double] = [:]
        for (key, recs) in beaconRSSLog {
            // 先把每筆 rec.rssi 再 clamp 一次
            let sanitized = recs.map { Double($0.rssi > -10 ? -90 : $0.rssi) }
            let sum = sanitized.reduce(0, +)
            avg[key] = sum / Double(sanitized.count)
        }
        return avg
    }

}
