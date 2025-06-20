//
//  ViewController.swift
//  iBeacon
//
//  Created by admin on 2025/4/15.
//

import UIKit
import CoreLocation
import CoreMotion

// MARK: - Data Structures
struct BeaconData {
    let rssi: Int
    let timestamp: Date
    let yaw: Double
}

struct BeaconPosition {
    let x: Double
    let y: Double
}

struct PathLossModel {
    let db0Path1: [Double]
    let pathLossCoeff1: [Double]
    let db0Path2: [Double]
    let pathLossCoeff2: [Double]
}

struct PositionResult {
    let beaconSequence: [Int]
    let rssiValues: [Double]
    let estimatedDistances: [Double]
    let predictedX: Double?
    let predictedY: Double?
    let positionError: Double?
    let region: String?  // 新增區域判斷
}

var beaconRSSLog: [String: [BeaconData]] = [:]

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    // MARK: - Properties
    var locationManager: CLLocationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    var currentYaw: Double = 0.0
    var isRecording: Bool = false {
        didSet {
            print("📝 Recording state changed: \(oldValue) -> \(isRecording)")
            DispatchQueue.main.async {
                self.updateUIForRecordingState()
            }
        }
    }
    
    // MARK: - Outlets
    @IBOutlet weak var rangingResultTextView: UITextView!
    @IBOutlet weak var monitorResultTextView: UITextView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var exportButton: UIButton!
    
    // MARK: - Constants
    let uuid = "77C99B62-88FC-4C78-B39C-D6FE06E76372"
    let identifier = "esd region"
    
    // Beacon positions in meters
    let beaconPositions: [Int: BeaconPosition] = [
        1: BeaconPosition(x: 3.5, y: 10.4),
        2: BeaconPosition(x: 0, y: 6.4),
        3: BeaconPosition(x: 5.6, y: 4.3),
        4: BeaconPosition(x: 2.4, y: 0)
    ]
    
    // Path loss model data
    let pathLossModel = PathLossModel(
        //db0Path1: [-54.02782975, -53.11334552, -52.64134175, -43.45102306],
        db0Path1: [-64.02782975, -56.11334552, -55.64134175, -48.45102306],
        pathLossCoeff1: [1.807728232, 1.344055173, 1.989321774, 2.833391943],
        //db0Path2: [-51.51594819, -50.11713296, -47.7927178, -47.96076588],
        db0Path2: [-61.51594819, -53.11713296, -50.7927178, -52.96076588],
        pathLossCoeff2: [2.124834846, 1.486451347, 2.853054181, 1.322591731]
    )
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🚀 ViewController loaded")
        setupLocationManager()
        setupMotionManager()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("👁️ View appeared - Current recording state: \(isRecording)")
        updateUIForRecordingState()
    }
    
    // MARK: - Setup Methods
    func setupLocationManager() {
        print("📍 Setting up location manager")
        locationManager.delegate = self
        
        if #available(iOS 14, *) {
            let currentStatus = locationManager.authorizationStatus
            print("📱 Current authorization status (iOS 14+): \(currentStatus.rawValue)")
            if currentStatus != .authorizedAlways {
                locationManager.requestAlwaysAuthorization()
            }
        } else {
            let currentStatus = CLLocationManager.authorizationStatus()
            print("📱 Current authorization status: \(currentStatus.rawValue)")
            if currentStatus != .authorizedAlways {
                locationManager.requestAlwaysAuthorization()
            }
        }
        
        let constraint = CLBeaconIdentityConstraint(uuid: UUID(uuidString: uuid)!)
        locationManager.startRangingBeacons(satisfying: constraint)
        print("📡 Started ranging beacons with UUID: \(uuid)")
    }
    
    func setupMotionManager() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.2
            motionManager.startDeviceMotionUpdates()
            print("🧭 Motion manager started")
            
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
                if let motion = self?.motionManager.deviceMotion {
                    let yawDegrees = motion.attitude.yaw * 180 / .pi
                    self?.currentYaw = yawDegrees
                }
            }
        } else {
            print("❌ Device motion not available")
        }
    }
    
    func setupUI() {
        monitorResultTextView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        monitorResultTextView.isEditable = false
        monitorResultTextView.isSelectable = true
        
        updateUIForRecordingState()
        print("🎨 UI setup completed")
    }
    
    func updateUIForRecordingState() {
        if isRecording {
            startButton.setTitle("Stop Recording", for: .normal)
            startButton.backgroundColor = UIColor.systemRed
            exportButton.isEnabled = false
            exportButton.alpha = 0.5
        } else {
            startButton.setTitle("Start Recording", for: .normal)
            startButton.backgroundColor = UIColor.systemBlue
            exportButton.isEnabled = !beaconRSSLog.isEmpty
            exportButton.alpha = beaconRSSLog.isEmpty ? 0.5 : 1.0
        }
        
        print("🎯 UI updated - Recording: \(isRecording), Data available: \(!beaconRSSLog.isEmpty)")
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        let timestamp = Date()
        let timestampString = DateFormatter.localizedString(from: timestamp, dateStyle: .none, timeStyle: .medium)
        
        // 更新畫面
        DispatchQueue.main.async {
            self.updateRangingDisplay(beacons: beacons, timestamp: timestampString)
        }
        
        guard isRecording else { return }
        
        for beacon in beacons {
            // 只處理 major == 1，遇到其他 major 就跳過
            if beacon.major.intValue != 1 {
                continue
            }
            
            let key = "\(beacon.major)-\(beacon.minor)"
            if beaconRSSLog[key] == nil {
                beaconRSSLog[key] = []
            }
            let beaconData = BeaconData(rssi: beacon.rssi, timestamp: timestamp, yaw: currentYaw)
            beaconRSSLog[key]?.append(beaconData)
        }
        
        DispatchQueue.main.async {
            self.updateRecordingStatus()
        }
    }

    
    func updateRangingDisplay(beacons: [CLBeacon], timestamp: String) {
        var displayText = "=== Beacon Ranging [\(timestamp)] ===\n\n"
        
        if beacons.isEmpty {
            displayText += "No beacons detected\n"
        } else {
            for beacon in beacons.sorted(by: { $0.rssi > $1.rssi }) {
                let yawString = String(format: "%.2f", currentYaw)
                displayText += "🔵 Beacon \(beacon.major)-\(beacon.minor)\n"
                displayText += "   RSSI: \(beacon.rssi) dBm\n"
                displayText += "   Yaw: \(yawString)°\n"
                displayText += "   Proximity: \(beacon.proximity.rawValue)\n\n"
            }
        }
        
        rangingResultTextView.text = displayText
    }
    
    func updateRecordingStatus() {
        if isRecording {
            let totalDataPoints = beaconRSSLog.values.map { $0.count }.reduce(0, +)
            let uniqueBeacons = beaconRSSLog.count
            
            var statusText = "🔴 RECORDING IN PROGRESS\n\n"
            statusText += "Unique beacons detected: \(uniqueBeacons)\n"
            statusText += "Total data points: \(totalDataPoints)\n\n"
            
            if !beaconRSSLog.isEmpty {
                statusText += "Data per beacon:\n"
                for (key, data) in beaconRSSLog.sorted(by: { $0.key < $1.key }) {
                    let avgRSSI = data.isEmpty ? 0 : data.map { $0.rssi }.reduce(0, +) / data.count
                    statusText += "  \(key): \(data.count) samples (avg RSSI: \(avgRSSI))\n"
                }
            }
            
            monitorResultTextView.text = statusText
        } else if !beaconRSSLog.isEmpty {
            let totalDataPoints = beaconRSSLog.values.map { $0.count }.reduce(0, +)
            monitorResultTextView.text = "✅ Recording completed\n\nData collected from \(beaconRSSLog.count) beacons\nTotal samples: \(totalDataPoints)\n\nReady to calculate position!"
        }
        
        updateUIForRecordingState()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager failed with error: \(error)")
        DispatchQueue.main.async {
            self.monitorResultTextView.text = "❌ Location error: \(error.localizedDescription)"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🔐 Authorization status changed to: \(status.rawValue)")
        
        DispatchQueue.main.async {
            switch status {
            case .notDetermined:
                self.locationManager.requestAlwaysAuthorization()
                self.monitorResultTextView.text = "⏳ Requesting location permission..."
            case .denied, .restricted:
                self.monitorResultTextView.text = "❌ Location access denied. Please enable in Settings → Privacy & Security → Location Services."
            case .authorizedWhenInUse:
                self.monitorResultTextView.text = "⚠️ Need 'Always' location permission for beacon ranging.\nPlease change to 'Always' in Settings."
            case .authorizedAlways:
                print("✅ Location authorized - starting beacon ranging")
                let constraint = CLBeaconIdentityConstraint(uuid: UUID(uuidString: self.uuid)!)
                self.locationManager.startRangingBeacons(satisfying: constraint)
                self.monitorResultTextView.text = "✅ Location authorized. Searching for beacons..."
            @unknown default:
                self.monitorResultTextView.text = "⚠️ Unknown authorization status"
            }
        }
    }
    
    // MARK: - Button Actions
    @IBAction func startButtonTapped(_ sender: UIButton) {
        print("🔘 Start button tapped! Current recording state: \(isRecording)")
        
        if isRecording {
            // Stop recording
            print("⏹️ Stopping recording...")
            isRecording = false
            print("📊 Final data summary:")
            for (key, data) in beaconRSSLog {
                print("  \(key): \(data.count) samples")
            }
        } else {
            // Start recording
            print("▶️ Starting recording...")
            beaconRSSLog.removeAll()
            isRecording = true
            
            DispatchQueue.main.async {
                self.monitorResultTextView.text = "🔴 Recording started...\nSearching for beacons...\n\nMake sure beacons are nearby and powered on."
            }
        }
    }
    
    @IBAction func exportButtonTapped(_ sender: UIButton) {
        print("📤 Export button tapped")
        
        if beaconRSSLog.isEmpty {
            print("⚠️ No data to process")
            monitorResultTextView.text = "⚠️ No data available. Please record some beacon data first."
            return
        }
        
        calculatePosition()
    }
    
    // MARK: - Position Calculation
    // 修正計算位置的主函數，增加更好的錯誤處理
    func calculatePosition() {
        print("🧮 Starting position calculation...")
        let averageRSSI = calculateAverageRSSI()
        
        print("📊 Average RSSI values: \(averageRSSI)")
        
        if averageRSSI.isEmpty {
            let message = "⚠️ No beacon data available for calculation."
            print(message)
            monitorResultTextView.text = message
            return
        }
        
        // 檢查 Beacon4 的 RSSI 是否小於 -55 dBm
        var filteredRSSI = averageRSSI
        if let beacon4Key = averageRSSI.keys.first(where: { $0.hasSuffix("-4") }),
           let beacon4RSSI = averageRSSI[beacon4Key],
           beacon4RSSI < -55 {
            
            print("⚠️ Beacon4 RSSI (\(beacon4RSSI)) < -55 dBm, removing from calculation")
            filteredRSSI.removeValue(forKey: beacon4Key)
            
            // 檢查是否還有足夠的 beacon 1,2,3
            let beacons123Keys = filteredRSSI.keys.filter { key in
                let minor = Int(key.split(separator: "-")[1])!
                return [1, 2, 3].contains(minor)
            }
            
            if beacons123Keys.count < 3 {
                let message = "⚠️ After excluding Beacon4 (RSSI < -55), only \(beacons123Keys.count) beacons [1,2,3] available.\nNeed at least 3 beacons for positioning."
                print(message)
                monitorResultTextView.text = message
                return
            }
            
            print("✅ Using beacons [1,2,3] after excluding Beacon4")
        }
        
        if filteredRSSI.count < 3 {
            let message = "⚠️ Need at least 3 beacons for position calculation.\nCurrently have: \(filteredRSSI.count) beacons"
            print(message)
            monitorResultTextView.text = message
            return
        }
        
        // Sort beacons by RSSI strength (strongest first) and take top 3
        let sortedBeacons = filteredRSSI.sorted { $0.value > $1.value }
        let top3Beacons = Array(sortedBeacons.prefix(3))
        
        let beaconSequence = top3Beacons.map { Int($0.key.split(separator: "-")[1])! }
        let rssiValues = top3Beacons.map { $0.value }
        
        print("🎯 Using top 3 beacons: \(beaconSequence) with RSSI: \(rssiValues)")
        
        // Select appropriate path loss model
        let (db0Values, pathLossCoeffs) = selectPathLossModel(beaconSequence: beaconSequence, rssiValues: rssiValues)
        
        // Calculate distances
        let estimatedDistances = calculateDistances(db0Values: db0Values, rssiValues: rssiValues, pathLossCoeffs: pathLossCoeffs)
        
        print("📏 Estimated distances: \(estimatedDistances)")
        
        // Perform trilateration
        let (predX, predY) = performTrilateration(beaconSequence: beaconSequence, distances: estimatedDistances)
        
        print("📍 Calculated position: (\(predX ?? -999), \(predY ?? -999))")
        
        // Display results
        displayResults(beaconSequence: beaconSequence, rssiValues: rssiValues,
                      estimatedDistances: estimatedDistances, predX: predX, predY: predY)
    }
    
    func calculateAverageRSSI() -> [String: Double] {
        var averageRSSI: [String: Double] = [:]
        
        for (key, dataList) in beaconRSSLog {
            if !dataList.isEmpty {
                let totalRSSI = dataList.reduce(0) { $0 + $1.rssi }
                averageRSSI[key] = Double(totalRSSI) / Double(dataList.count)
            }
        }
        
        return averageRSSI
    }
    
    func selectPathLossModel(
        beaconSequence: [Int],
        rssiValues: [Double]
    ) -> ([Double], [Double]) {
        // 1) 建立 BeaconID ↔ RSSI 的對應字典
        let beaconRSSI = Dictionary(uniqueKeysWithValues: zip(beaconSequence, rssiValues))
        
        // 2) 檢查是否有 Beacon4 且其 RSSI < -55 dBm
        if let beacon4Index = beaconSequence.firstIndex(of: 4),
           rssiValues[beacon4Index] < -55 {
            
            print("⚠️ Beacon4 RSSI (\(rssiValues[beacon4Index])) < -55 dBm, excluding Beacon4")
            
            // 2.1 檢查是否有足夠的 beacon 1,2,3 資料
            let availableBeacons = beaconSequence.filter { $0 != 4 }
            let beacons123 = availableBeacons.filter { [1, 2, 3].contains($0) }
            
            if beacons123.count >= 3 {
                // 有足夠的 beacon 1,2,3，使用它們
                let seq123 = beacons123.sorted()  // 確保順序一致
                let rssi123 = seq123.compactMap { beaconRSSI[$0] }
                
                print("✅ Using beacons \(seq123) instead of Beacon4")
                
                // 遞迴呼叫，用新的序列重新計算
                return selectPathLossModel(
                    beaconSequence: seq123,
                    rssiValues: rssi123
                )
            } else {
                // 沒有足夠的 beacon 1,2,3，保持原序列但給出警告
                print("⚠️ Insufficient beacons [1,2,3] available, keeping original sequence")
            }
        }
        
        // 3) 正常的路徑選擇邏輯（原本的四種組合判斷）
        return getPathLossValues(for: beaconSequence, rssiDict: beaconRSSI)
    }

    // 輔助函數：安全地獲取路徑損失值
    private func getPathLossValues(for beaconSequence: [Int], rssiDict: [Int: Double]) -> ([Double], [Double]) {
        let beaconSet = Set(beaconSequence)
        var db0Values: [Double] = []
        var pathLossCoeffs: [Double] = []
        
        if beaconSet == Set([2,3,4]) {
            // 二元假設：H1 if P2 > P3 → beacon4 用 path1，else 都 path2
            guard let rssi2 = rssiDict[2], let rssi3 = rssiDict[3] else {
                // 如果無法獲取必要的 RSSI 值，使用預設 path1
                return getDefaultPathLossValues(for: beaconSequence, usePathOne: true)
            }
            
            if rssi2 > rssi3 {
                for b in beaconSequence {
                    if b == 4 {
                        db0Values.append(pathLossModel.db0Path1[b-1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff1[b-1])
                    } else {
                        db0Values.append(pathLossModel.db0Path2[b-1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff2[b-1])
                    }
                }
            } else {
                for b in beaconSequence {
                    db0Values.append(pathLossModel.db0Path2[b-1])
                    pathLossCoeffs.append(pathLossModel.pathLossCoeff2[b-1])
                }
            }
        }
        else if beaconSet == Set([1,3,4]) {
            // H1 if P1 > P4 → beacon3 用 path1，其餘 path2；else 全 path2
            guard let rssi1 = rssiDict[1], let rssi4 = rssiDict[4] else {
                return getDefaultPathLossValues(for: beaconSequence, usePathOne: true)
            }
            
            if rssi1 > rssi4 {
                for b in beaconSequence {
                    if b == 3 {
                        db0Values.append(pathLossModel.db0Path1[b-1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff1[b-1])
                    } else {
                        db0Values.append(pathLossModel.db0Path2[b-1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff2[b-1])
                    }
                }
            } else {
                for b in beaconSequence {
                    db0Values.append(pathLossModel.db0Path2[b-1])
                    pathLossCoeffs.append(pathLossModel.pathLossCoeff2[b-1])
                }
            }
        }
        else if beaconSet == Set([1,2,4]) {
            // H1 if P1 > P4 → 全 path1；else beacon2 path2，其餘 path1
            guard let rssi1 = rssiDict[1], let rssi4 = rssiDict[4] else {
                return getDefaultPathLossValues(for: beaconSequence, usePathOne: true)
            }
            
            if rssi1 > rssi4 {
                for b in beaconSequence {
                    db0Values.append(pathLossModel.db0Path1[b-1])
                    pathLossCoeffs.append(pathLossModel.pathLossCoeff1[b-1])
                }
            } else {
                for b in beaconSequence {
                    if b == 2 {
                        db0Values.append(pathLossModel.db0Path2[b-1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff2[b-1])
                    } else {
                        db0Values.append(pathLossModel.db0Path1[b-1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff1[b-1])
                    }
                }
            }
        }
        else if beaconSet == Set([1,2,3]) {
            // H1 if P2 > P3 → 全 path1；else beacon1 path2，其餘 path1
            guard let rssi2 = rssiDict[2], let rssi3 = rssiDict[3] else {
                return getDefaultPathLossValues(for: beaconSequence, usePathOne: true)
            }
            
            if rssi2 > rssi3 {
                for b in beaconSequence {
                    db0Values.append(pathLossModel.db0Path1[b-1])
                    pathLossCoeffs.append(pathLossModel.pathLossCoeff1[b-1])
                }
            } else {
                for b in beaconSequence {
                    if b == 1 {
                        db0Values.append(pathLossModel.db0Path2[b-1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff2[b-1])
                    } else {
                        db0Values.append(pathLossModel.db0Path1[b-1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff1[b-1])
                    }
                }
            }
        }
        else {
            // 其餘預設全走 path1
            return getDefaultPathLossValues(for: beaconSequence, usePathOne: true)
        }
        
        return (db0Values, pathLossCoeffs)
    }

    // 安全的預設值獲取函數
    private func getDefaultPathLossValues(for beaconSequence: [Int], usePathOne: Bool) -> ([Double], [Double]) {
        var db0Values: [Double] = []
        var pathLossCoeffs: [Double] = []
        
        for b in beaconSequence {
            // 確保索引在有效範圍內
            let index = b - 1
            if index >= 0 && index < pathLossModel.db0Path1.count {
                if usePathOne {
                    db0Values.append(pathLossModel.db0Path1[index])
                    pathLossCoeffs.append(pathLossModel.pathLossCoeff1[index])
                } else {
                    db0Values.append(pathLossModel.db0Path2[index])
                    pathLossCoeffs.append(pathLossModel.pathLossCoeff2[index])
                }
            }
        }
        
        return (db0Values, pathLossCoeffs)
    }
    func calculateDistances(db0Values: [Double], rssiValues: [Double], pathLossCoeffs: [Double]) -> [Double] {
        var distances: [Double] = []
        
        for i in 0..<db0Values.count {
            let result = (db0Values[i] - rssiValues[i]) / (10 * pathLossCoeffs[i])
            let distance = pow(10, result)
            distances.append(distance)
        }
        
        return distances
    }
    
    func performTrilateration(beaconSequence: [Int], distances: [Double]) -> (Double?, Double?) {
        guard beaconSequence.count >= 3 && distances.count >= 3 else {
            return (nil, nil)
        }
        
        let p1 = beaconPositions[beaconSequence[0]]!
        let p2 = beaconPositions[beaconSequence[1]]!
        let p3 = beaconPositions[beaconSequence[2]]!
        
        let r1 = distances[0]
        let r2 = distances[1]
        let r3 = distances[2]
        
        // Trilateration algorithm
        let A = 2 * (p2.x - p1.x)
        let B = 2 * (p2.y - p1.y)
        let C = pow(r1, 2) - pow(r2, 2) - pow(p1.x, 2) + pow(p2.x, 2) - pow(p1.y, 2) + pow(p2.y, 2)
        let D = 2 * (p3.x - p2.x)
        let E = 2 * (p3.y - p2.y)
        let F = pow(r2, 2) - pow(r3, 2) - pow(p2.x, 2) + pow(p3.x, 2) - pow(p2.y, 2) + pow(p3.y, 2)
        
        let denominator = A * E - B * D
        
        if abs(denominator) < 1e-10 {
            return (nil, nil) // Lines are parallel
        }
        
        let x = (C * E - F * B) / denominator
        let y = (A * F - D * C) / denominator
        
        return (x, y)
    }
    
    // MARK: - Region Detection (新增的功能)
    func determineRegionFromY(_ yCoordinate: Double) -> String {
        if yCoordinate < 3.2 {
            return "C"
        } else if yCoordinate >= 3.2 && yCoordinate <= 7.2 {
            return "B"
        } else {
            return "A"
        }
    }
    
    func displayResults(beaconSequence: [Int], rssiValues: [Double],
                       estimatedDistances: [Double], predX: Double?, predY: Double?) {
        var resultText = "=== 🎯 Position Calculation Results ===\n\n"
        
        // 檢查是否排除了 Beacon4
        let hasBeacon4 = beaconSequence.contains(4)
        if !hasBeacon4 && beaconRSSLog.keys.contains(where: { $0.hasSuffix("-4") }) {
            resultText += "⚠️ Beacon4 was excluded (RSSI < -55 dBm)\n\n"
        }
        
        resultText += "📡 Selected Beacons: \(beaconSequence)\n"
        resultText += "📊 Average RSSI: \(rssiValues.map { String(format: "%.2f", $0) })\n"
        resultText += "📏 Estimated Distances: \(estimatedDistances.map { String(format: "%.3f", $0) })m\n\n"
        
        var region: String? = nil
        
        if let x = predX, let y = predY {
            resultText += "📍 Predicted Position: (\(String(format: "%.3f", x)), \(String(format: "%.3f", y)))\n"
            
            // 根據 Y 軸座標判斷區域
            region = determineRegionFromY(y)
            resultText += "🏷️ Region: \(region!)\n"
            
            // 顯示區域判斷邏輯
            resultText += "\n=== 🗺️ Region Classification ===\n"
            resultText += "Y < 3.2: Region C\n"
            resultText += "3.2 ≤ Y ≤ 7.2: Region B\n"
            resultText += "Y > 7.2: Region A\n"
            resultText += "Current Y = \(String(format: "%.3f", y)) → Region \(region!)\n"
            
        } else {
            resultText += "❌ Unable to calculate position - trilateration failed\n"
        }
        
        // Show beacon positions for reference
        resultText += "\n=== 🗺️ Beacon Reference Positions ===\n"
        for beacon in beaconSequence {
            if let pos = beaconPositions[beacon] {
                resultText += "Beacon \(beacon): (\(pos.x), \(pos.y))m\n"
            }
        }
        
        // 顯示篩選資訊
        resultText += "\n=== ℹ️ Beacon Selection Info ===\n"
        let allBeacons = beaconRSSLog.keys.map { Int($0.split(separator: "-")[1])! }.sorted()
        resultText += "Available beacons: \(allBeacons)\n"
        resultText += "Used for calculation: \(beaconSequence)\n"
        
        if !hasBeacon4 && allBeacons.contains(4) {
            if let beacon4Data = beaconRSSLog["1-4"] {
                let avgRSSI = beacon4Data.map { $0.rssi }.reduce(0, +) / beacon4Data.count
                resultText += "Beacon4 excluded: RSSI \(avgRSSI) < -55 dBm\n"
            }
        }
        
        monitorResultTextView.text = resultText
        
        // Save results to CSV
        let fileURL = savePositionResultToCSV(beaconSequence: beaconSequence, rssiValues: rssiValues,
                                             estimatedDistances: estimatedDistances, predX: predX, predY: predY, region: region)
        print("💾 Results saved to: \(fileURL.lastPathComponent)")
    }
    
    // MARK: - File Operations
    func savePositionResultToCSV(beaconSequence: [Int], rssiValues: [Double],
                                estimatedDistances: [Double], predX: Double?, predY: Double?, region: String?) -> URL {
        let filenameFormatter = DateFormatter()
        filenameFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = filenameFormatter.string(from: Date())
        let filename = "position_result_\(timestamp).csv"
        
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0]
        let fileURL = documentDirectory.appendingPathComponent(filename)
        
        var csvText = "Beacon_Sequence,RSSI_Values,Estimated_Distances,Predicted_X,Predicted_Y,Region\n"
        
        let beaconSeqStr = beaconSequence.map(String.init).joined(separator: ";")
        let rssiStr = rssiValues.map { String(format: "%.2f", $0) }.joined(separator: ";")
        let distStr = estimatedDistances.map { String(format: "%.3f", $0) }.joined(separator: ";")
        let xStr = predX != nil ? String(format: "%.3f", predX!) : "N/A"
        let yStr = predY != nil ? String(format: "%.3f", predY!) : "N/A"
        let regionStr = region ?? "N/A"
        
        csvText += "\(beaconSeqStr),\(rssiStr),\(distStr),\(xStr),\(yStr),\(regionStr)\n"
        
        do {
            try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ Position results saved to: \(fileURL.lastPathComponent)")
        } catch {
            print("❌ Save error: \(error)")
        }
        
        return fileURL
    }
}
