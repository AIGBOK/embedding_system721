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
}

var beaconRSSLog: [String: [BeaconData]] = [:]

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    // MARK: - Properties
    var locationManager: CLLocationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    var currentYaw: Double = 0.0
    var isRecording: Bool = false
    
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
        db0Path1: [-54.02782975, -53.11334552, -52.64134175, -43.45102306],
        pathLossCoeff1: [1.807728232, 1.344055173, 1.989321774, 2.833391943],
        db0Path2: [-51.51594819, -50.11713296, -47.7927178, -47.96076588],
        pathLossCoeff2: [2.124834846, 1.486451347, 2.853054181, 1.322591731]
    )
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationManager()
        setupMotionManager()
        setupUI()
    }
    
    // MARK: - Setup Methods
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
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.2
            motionManager.startDeviceMotionUpdates()
            
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
                if let motion = self?.motionManager.deviceMotion {
                    let yawDegrees = motion.attitude.yaw * 180 / .pi
                    self?.currentYaw = yawDegrees
                }
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
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        rangingResultTextView.text = ""
        
        if !isRecording { return }
        
        for beacon in beacons {
            let key = "\(beacon.major)-\(beacon.minor)"
            if beaconRSSLog[key] == nil {
                beaconRSSLog[key] = []
            }
            
            let beaconData = BeaconData(rssi: beacon.rssi, timestamp: Date(), yaw: currentYaw)
            beaconRSSLog[key]?.append(beaconData)
            
            let yawString = String(format: "%.2f", currentYaw)
            rangingResultTextView.text +=
                "Major: \(beacon.major)  Minor: \(beacon.minor)\n" +
                "RSSI: \(beacon.rssi)  Yaw: \(yawString)°\n\n"
        }
    }
    
    // MARK: - Button Actions
    @IBAction func startButtonTapped(_ sender: UIButton) {
        if isRecording {
            // Stop recording
            isRecording = false
            startButton.setTitle("Start Recording", for: .normal)
            exportButton.isEnabled = true
            monitorResultTextView.text = "Recording stopped. Ready to calculate position."
        } else {
            // Start recording
            beaconRSSLog.removeAll()
            isRecording = true
            startButton.setTitle("Stop Recording", for: .normal)
            exportButton.isEnabled = false
            monitorResultTextView.text = "Recording started..."
        }
    }
    
    @IBAction func exportButtonTapped(_ sender: UIButton) {
        calculatePosition()
    }
    
    // MARK: - Position Calculation
    func calculatePosition() {
        let averageRSSI = calculateAverageRSSI()
        
        if averageRSSI.count < 3 {
            monitorResultTextView.text = "需要至少3個beacon的數據來計算位置"
            return
        }
        
        // Sort beacons by RSSI strength (strongest first) and take top 3
        let sortedBeacons = averageRSSI.sorted { $0.value > $1.value }
        let top3Beacons = Array(sortedBeacons.prefix(3))
        
        let beaconSequence = top3Beacons.map { Int($0.key.split(separator: "-")[1])! }
        let rssiValues = top3Beacons.map { $0.value }
        
        // Select appropriate path loss model
        let (db0Values, pathLossCoeffs) = selectPathLossModel(beaconSequence: beaconSequence, rssiValues: rssiValues)
        
        // Calculate distances
        let estimatedDistances = calculateDistances(db0Values: db0Values, rssiValues: rssiValues, pathLossCoeffs: pathLossCoeffs)
        
        // Perform trilateration
        let (predX, predY) = performTrilateration(beaconSequence: beaconSequence, distances: estimatedDistances)
        
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
    
    func selectPathLossModel(beaconSequence: [Int], rssiValues: [Double]) -> ([Double], [Double]) {
        var db0Values: [Double] = []
        var pathLossCoeffs: [Double] = []
        
        let beaconSet = Set(beaconSequence)
        let beaconRSSI = Dictionary(zip(beaconSequence, rssiValues))
        
        if beaconSet == Set([2, 3, 4]) {
            if beaconRSSI[2]! > beaconRSSI[3]! {
                for beacon in beaconSequence {
                    if beacon == 4 {
                        db0Values.append(pathLossModel.db0Path1[beacon - 1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff1[beacon - 1])
                    } else {
                        db0Values.append(pathLossModel.db0Path2[beacon - 1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff2[beacon - 1])
                    }
                }
            } else {
                for beacon in beaconSequence {
                    if beacon == 4 {
                        db0Values.append(pathLossModel.db0Path2[beacon - 1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff2[beacon - 1])
                    } else {
                        db0Values.append(pathLossModel.db0Path2[beacon - 1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff2[beacon - 1])
                    }
                }
            }
        } else if beaconSet == Set([1, 3, 4]) {
            if beaconRSSI[1]! > beaconRSSI[4]! {
                for beacon in beaconSequence {
                    if beacon == 3 {
                        db0Values.append(pathLossModel.db0Path1[beacon - 1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff1[beacon - 1])
                    } else {
                        db0Values.append(pathLossModel.db0Path2[beacon - 1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff2[beacon - 1])
                    }
                }
            } else {
                for beacon in beaconSequence {
                    if beacon == 3 {
                        db0Values.append(pathLossModel.db0Path2[beacon - 1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff2[beacon - 1])
                    } else {
                        db0Values.append(pathLossModel.db0Path2[beacon - 1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff2[beacon - 1])
                    }
                }
            }
        } else if beaconSet == Set([1, 2, 4]) {
            if beaconRSSI[1]! > beaconRSSI[4]! {
                for beacon in beaconSequence {
                    if beacon == 2 {
                        db0Values.append(pathLossModel.db0Path1[beacon - 1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff1[beacon - 1])
                    } else {
                        db0Values.append(pathLossModel.db0Path1[beacon - 1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff1[beacon - 1])
                    }
                }
            } else {
                for beacon in beaconSequence {
                    if beacon == 2 {
                        db0Values.append(pathLossModel.db0Path2[beacon - 1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff2[beacon - 1])
                    } else {
                        db0Values.append(pathLossModel.db0Path1[beacon - 1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff1[beacon - 1])
                    }
                }
            }
        } else if beaconSet == Set([1, 2, 3]) {
            if beaconRSSI[2]! > beaconRSSI[3]! {
                for beacon in beaconSequence {
                    if beacon == 1 {
                        db0Values.append(pathLossModel.db0Path1[beacon - 1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff1[beacon - 1])
                    } else {
                        db0Values.append(pathLossModel.db0Path1[beacon - 1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff1[beacon - 1])
                    }
                }
            } else {
                for beacon in beaconSequence {
                    if beacon == 1 {
                        db0Values.append(pathLossModel.db0Path2[beacon - 1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff2[beacon - 1])
                    } else {
                        db0Values.append(pathLossModel.db0Path1[beacon - 1])
                        pathLossCoeffs.append(pathLossModel.pathLossCoeff1[beacon - 1])
                    }
                }
            }
        } else {
            // Default case - use path1 for all
            for beacon in beaconSequence {
                db0Values.append(pathLossModel.db0Path1[beacon - 1])
                pathLossCoeffs.append(pathLossModel.pathLossCoeff1[beacon - 1])
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
    
    func displayResults(beaconSequence: [Int], rssiValues: [Double], 
                       estimatedDistances: [Double], predX: Double?, predY: Double?) {
        var resultText = "=== 位置計算結果 ===\n\n"
        
        resultText += "使用的Beacon序列: \(beaconSequence)\n"
        resultText += "平均RSSI值: \(rssiValues.map { String(format: "%.2f", $0) })\n"
        resultText += "估計距離: \(estimatedDistances.map { String(format: "%.3f", $0) })m\n\n"
        
        if let x = predX, let y = predY {
            resultText += "預測位置: (\(String(format: "%.3f", x)), \(String(format: "%.3f", y)))\n"
        } else {
            resultText += "無法計算位置 - 三角定位失敗\n"
        }
        
        // Show beacon positions for reference
        resultText += "\n=== Beacon位置參考 ===\n"
        for beacon in beaconSequence {
            if let pos = beaconPositions[beacon] {
                resultText += "Beacon \(beacon): (\(pos.x), \(pos.y))\n"
            }
        }
        
        monitorResultTextView.text = resultText
        
        // Save results to CSV if needed
        _ = savePositionResultToCSV(beaconSequence: beaconSequence, rssiValues: rssiValues, 
                                   estimatedDistances: estimatedDistances, predX: predX, predY: predY)
    }
    
    // MARK: - File Operations
    func savePositionResultToCSV(beaconSequence: [Int], rssiValues: [Double], 
                                estimatedDistances: [Double], predX: Double?, predY: Double?) -> URL {
        let filenameFormatter = DateFormatter()
        filenameFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = filenameFormatter.string(from: Date())
        let filename = "position_result_\(timestamp).csv"
        
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls[0]
        let fileURL = documentDirectory.appendingPathComponent(filename)
        
        var csvText = "Beacon_Sequence,RSSI_Values,Estimated_Distances,Predicted_X,Predicted_Y\n"
        
        let beaconSeqStr = beaconSequence.map(String.init).joined(separator: ";")
        let rssiStr = rssiValues.map { String(format: "%.2f", $0) }.joined(separator: ";")
        let distStr = estimatedDistances.map { String(format: "%.3f", $0) }.joined(separator: ";")
        let xStr = predX != nil ? String(format: "%.3f", predX!) : "N/A"
        let yStr = predY != nil ? String(format: "%.3f", predY!) : "N/A"
        
        csvText += "\(beaconSeqStr),\(rssiStr),\(distStr),\(xStr),\(yStr)\n"
        
        do {
            try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ 位置結果已儲存到: \(fileURL.lastPathComponent)")
        } catch {
            print("❌ 儲存錯誤: \(error)")
        }
        
        return fileURL
    }
}
