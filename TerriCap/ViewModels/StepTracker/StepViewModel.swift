//
//  StepViewModel.swift
//  step tracker
//
//  Created by 濱松未波 on 2025/11/19.
//
import Foundation
import Combine
import CoreLocation

class StepViewModel: NSObject, ObservableObject, PedometerManagerDelegate, HealthKitManagerDelegate, LocationServiceDelegate {

    // MARK: - データ管理
    @Published var cmLogInt: Int = 0      // 現在の歩数
    @Published var targetSteps: Int? = nil    // 目標歩数
    @Published var isTaskCleared: Bool = false // クリアしたかどうかのフラグ

    @Published var activityText: String = "活動認識待機中..."
    @Published var hkLogText: String = "---"
    @Published var statusText: String = "測定待機中"
    @Published var currentLocation: CLLocation?
    @Published var targetLocation: Location?

    private var initialOffset: Int = 0
    private var rawTotalSteps: Int = 0
    private var isMeasuring: Bool = false

    var distanceDisplayString: String? {
        guard let userLoc = currentLocation,
              let target = targetLocation else {
            return nil
        }
        let targetLoc = CLLocation(latitude: target.latitude, longitude: target.longitude)
        let rawDistance = userLoc.distance(from: targetLoc)
        let roundedDistance = (rawDistance / 10).rounded() * 10

        if roundedDistance >= 1000 {
            return String(format: "%.1f km", roundedDistance / 1000)
        } else {
            return String(format: "%.0f m", roundedDistance)
        }
    }
    var rawDistanceToTarget: Double? {
        guard let userLoc = currentLocation,
              let target = targetLocation else {
            return nil
        }
        let targetLoc = CLLocation(latitude: target.latitude, longitude: target.longitude)
        return userLoc.distance(from: targetLoc)
    }

    private var pedometerService: PedometerServiceType
    private var locationService: LocationServiceType
    private var healthKitService: HealthKitServiceType

    init(
        pedometerService: PedometerServiceType,
        locationService: LocationServiceType,
        healthKitService: HealthKitServiceType
    ) {
        self.pedometerService = pedometerService
        self.locationService = locationService
        self.healthKitService = healthKitService
        super.init()

        self.pedometerService.delegate = self
        self.locationService.delegate = self
        self.healthKitService.delegate = self
        self.pedometerService.startUpdates()
    }

    func setup() {
        locationService.setup()
        Task {
            do {
                try await healthKitService.requestAuthorization()
            } catch {
                print("HealthKit Authorization Failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 目標設定
    func setTargetLocation(_ location: Location) {
        self.targetLocation = location
        self.isTaskCleared = false
        if let firstTask = location.tasks?.first {
            let goal = firstTask.goal_move_value
            self.targetSteps = goal
            print("目標設定: \(goal)歩")
            checkTaskCondition()
        } else {
            self.targetSteps = nil
            print("目標歩数が設定されていません")
        }
    }

    // MARK: - 測定開始
    func startMeasurement(target: Location? = nil) {
        if let location = target {
            self.setTargetLocation(location)
        }
        print("測定開始")
        self.statusText = "測定中"
        self.isMeasuring = true
        self.initialOffset = self.rawTotalSteps
        self.cmLogInt = 0
        checkTaskCondition()
        LiveActivityManager.shared.start(initialSteps: 0, activityStatus: self.activityText)
        pedometerService.startUpdates()
        locationService.startUpdateLocation()
        healthKitService.startStepCountUpdates()
        fetchLatestHealthKitSteps()
    }

    // MARK: - 測定終了
    func stopMeasurement() {
        print("🛑 測定終了")
        self.statusText = "測定終了"
        self.isMeasuring = false
        self.cmLogInt = 0
        LiveActivityManager.shared.stop()

        locationService.stopUpdateLocation()
    }

    // MARK: - 歩数更新 (CoreMotion)
    func pedometerManager(_ manager: PedometerManager, didUpdateNumberOfSteps steps: NSNumber) {
        let totalSteps = steps.intValue

        DispatchQueue.main.async {
            self.rawTotalSteps = totalSteps

            if self.isMeasuring {
                let sessionSteps = totalSteps - self.initialOffset
                let displaySteps = max(0, sessionSteps)

                self.cmLogInt = displaySteps
                LiveActivityManager.shared.update(steps: displaySteps, activityStatus: self.activityText)

                self.checkTaskCondition()
            }
        }
    }

    // MARK: - 達成判定ロジック
    private func checkTaskCondition() {
        guard let target = targetSteps else { return }

        if isMeasuring && cmLogInt >= target {
            if !isTaskCleared {
                isTaskCleared = true
                statusText = "条件達成！"
                print("タスククリア 現在:\(cmLogInt) / 目標:\(target)")
            }
            self.checkOccupyStatus()
        } else {
            isTaskCleared = false
        }
    }

    // MARK: - その他デリゲートメソッド
    func pedometerManager(_ manager: PedometerManager, didUpdateActivity activity: String) {
        DispatchQueue.main.async { self.activityText = activity

            if self.isMeasuring {
                LiveActivityManager.shared.update(steps: self.cmLogInt, activityStatus: activity)
            }
        }
    }

    func healthKitManager(_ manager: HealthKitServiceType, didUpdateNumberOfSteps steps: Double) {
        DispatchQueue.main.async { self.hkLogText = "\(Int(steps)) 歩" }
    }

    func fetchLatestHealthKitSteps() {
        Task {
            let now = Date()
            let startOfDay = Calendar.current.startOfDay(for: now)
            if let sumSteps = await healthKitService.fetchStepCountSum(from: startOfDay, to: now) {
                self.healthKitManager(self.healthKitService, didUpdateNumberOfSteps: sumSteps)
            }
        }
    }

    func locationManager(_ manager: LocationServiceType, didUpdateLocation location: CLLocation) {
        DispatchQueue.main.async { self.currentLocation = location
            if self.isMeasuring {
                self.checkOccupyStatus()
            }
        }
    }

    private func checkOccupyStatus() {
        // 距離が150m以内 かつ タスククリア済み かどうか
        if let dist = rawDistanceToTarget, dist <= 150, isTaskCleared {
            print("選択しているスポットを占有可能です")
        }
    }
}
