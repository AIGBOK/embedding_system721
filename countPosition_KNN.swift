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

    // MARK: - Constants for KNN Fingerprinting
    // y-coordinates for grid positions
    let yVector: [Double] = [0.54, 1.22, 1.88, 2.57, 3.2]

    // Database vectors (hard‑coded fingerprinting database)
    let dbVectors: [[Double]] = [
        [-55.29, -60.20, -60.18, -64.47, -68.33, -69.11, -75.55, -66.67],
        [-41.35, -65.31, -55.96, -70.03, -65.42, -64.63, -77.38, -79.42],
        // ... (省略其餘 100 個群組的 8 維向量) ...
    ]

    let dbLabels: [String] = [
        "group1", "group2", /* ... */ "group102"
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
            let status = locationManager.authorizationStatus
            if status != .authorizedAlways {
                locationManager.requestAlwaysAuthorization()
            }
        } else {
            let status = CLLocationManager.authorizationStatus()
            if status != .authorizedAlways {
                locationManager.requestAlwaysAuthorization()
            }
        }
        let constraint = CLBeaconIdentityConstraint(uuid: UUID(uuidString: "77C99B62-88FC-4C78-B39C-D6FE06E76372" )!, major: 0, minor: 0)
        locationManager.startRangingBeacons(satisfying: constraint)
    }

    func setupMotionManager() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.2
        motionManager.startDeviceMotionUpdates()
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            if let attitude = self?.motionManager.deviceMotion?.attitude {
                self?.currentYaw = attitude.yaw * 180 / .pi
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

    // MARK: - Beacon Callback
    func locationManager(_ manager: CLLocationManager,
                         didRangeBeacons beacons: [CLBeacon],
                         in region: CLBeaconRegion) {
        guard isRecording else { return }
        rangingResultTextView.text = ""
        for beacon in beacons {
            let key = "\(beacon.major)-\(beacon.minor)"
            if beaconRSSLog[key] == nil {
                beaconRSSLog[key] = []
            }
            let data = BeaconData(rssi: beacon.rssi,
                                  timestamp: Date(),
                                  yaw: currentYaw)
            beaconRSSLog[key]?.append(data)
            let yawStr = String(format: "%.2f", currentYaw)
            rangingResultTextView.text +=
                "Major: \(beacon.major)  Minor: \(beacon.minor)\n" +
                "RSSI: \(beacon.rssi)  Yaw: \(yawStr)°\n\n"
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
        // 1. Export recorded raw data to CSV (same format as Python testpoint)
        let csvURL = saveBeaconDataToCSV()
        // 2. Load & process CSV into test vectors
        let (testVectors, _) = loadAndProcessCSV(at: csvURL)
        guard !testVectors.isEmpty else {
            monitorResultTextView.text = "No valid test vectors generated."
            return
        }
        // 3. Run KNN
        let results = knnMatch(testVectors: testVectors, k: 3)
        guard let first = results.first else {
            monitorResultTextView.text = "KNN returned no results."
            return
        }
        // 4. Display
        var txt = "=== Fingerprint KNN Result ===\n"
        txt += "TestGroup: \(first.testGroup)\n"
        txt += "Estimated Position: (x=\(String(format: "%.2f", first.x)), y=\(String(format: "%.2f", first.y)))\n"
        txt += "Matched DB Groups: \(first.matchedGroups)\n"
        monitorResultTextView.text = txt
    }

    // MARK: - CSV I/O Helpers
    func saveBeaconDataToCSV() -> URL {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd_HHmmss"
        let ts = df.string(from: Date())
        let filename = "testpoint_\(ts).csv"
        let docs = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(filename)
        // Build CSV with same structure as Python: time range + 8 rows of (rowId, avg, dBm)
        var text = "Major,Minor"
        for i in 1...8 { text += ",RSSI\(i)" }
        text += "\n"
        // For simplicity, write one group: take last 8 readings of each beacon and output
        for (key, list) in beaconRSSLog {
            let comps = key.split(separator: "-")
            guard list.count >= 8,
                  let major = comps.first,
                  let minor = comps.last else { continue }
            let slice = list.suffix(8)
            var line = "\(major),\(minor)"
            for data in slice {
                line += ",\(data.rssi)"
            }
            text += line + "\n"
        }
        try? text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func loadAndProcessCSV(at url: URL) -> ([[Double]], [String]) {
        guard let raw = try? String(contentsOf: url) else {
            return ([], [])
        }
        let lines = raw.components(separatedBy: "\n")
        var diffVectors: [[Double]] = []
        var labels: [String] = []
        var idx = 0
        while idx < lines.count {
            let cols = lines[idx].components(separatedBy: ",")
            // 找到 Major,Minor 開頭的行
            if cols.count >= 2, let _ = Double(cols[0]), let _ = Double(cols[1]) {
                // 這是資料行，讀取 8 維向量
                var vec: [Double] = []
                for j in 2..<min(cols.count, 10) {
                    if let v = Double(cols[j]) {
                        vec.append(v)
                    }
                }
                if vec.count == 8 {
                    diffVectors.append(vec)
                    labels.append("test\(diffVectors.count)")
                }
            }
            idx += 1
        }
        return (diffVectors, labels)
    }

    func computePosition(groupNumber: Int) -> (Double, Double) {
        // 同 Python compute_position
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
            // 計算歐氏距離
            let distances = dbVectors.map { db -> Double in
                zip(db, test).map { (a, b) in (a - b)*(a - b) }.reduce(0, +).squareRoot()
            }
            let sorted = distances.enumerated().sorted { $0.element < $1.element }
            let topK = sorted.prefix(k)
            var positions: [(Double, Double)] = []
            var matched: [String] = []
            var dists: [Double] = []
            for (idx, dist) in topK {
                let groupNum = idx + 1
                let (x, y) = computePosition(groupNumber: groupNum)
                positions.append((x, y))
                matched.append(dbLabels[idx])
                dists.append(dist)
            }
            let xs = positions.map { $0.0 }
            let ys = positions.map { $0.1 }
            let avgX = xs.reduce(0, +) / Double(xs.count)
            let avgY = ys.reduce(0, +) / Double(ys.count)
            results.append(
                PositionResult(
                    testGroup: "test\(i+1)",
                    x: avgX, y: avgY,
                    matchedGroups: matched,
                    distances: dists,
                    rssiValues: test
                )
            )
        }
        return results
    }
}
