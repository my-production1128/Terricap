//
//  StepViewModel.swift
//  step tracker
//
//  Created by 濱松未波 on 2025/11/19.
//
import Foundation
import Combine

class StepViewModel: NSObject, ObservableObject, PedometerManagerDelegate, HealthKitManagerDelegate {

    @Published var cmLogText: String = "---"
    @Published var activityText: String = "活動認識待機中..."
    @Published var hkLogText: String = "---"
    @Published var statusText: String = "初期化中..."

    private let pedometerService: PedometerServiceType
    private let locationService: LocationServiceType
    private let healthKitService: HealthKitServiceType

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
        self.healthKitService.delegate = self
    }

    func setup() {
        locationService.setup()
        NotificationManager.shared.requestPermission()

        Task {
            do {
                try await healthKitService.requestAuthorization()
                print("HealthKit Authorization Succeeded")
            } catch {
                print("HealthKit Authorization Failed: \(error.localizedDescription)")
            }
        }
    }

    func startMeasurement() {
        print("start")
        self.statusText = "測定開始しました (CoreMotion & HealthKit)"
        self.activityText = "活動認識待機中..."

        self.cmLogText = "0"

        LiveActivityManager.shared.start(initialSteps: 0)
        pedometerService.startUpdates()
        locationService.startUpdateLocation()
        healthKitService.startStepCountUpdates()
        fetchLatestHealthKitSteps()

        Task {
            let now = Date()
            let startOfDay = Calendar.current.startOfDay(for: now)
            if let sumSteps = await healthKitService.fetchStepCountSum(from: startOfDay, to: now) {
                self.healthKitManager(self.healthKitService, didUpdateNumberOfSteps: sumSteps)
                print("dbg HealthKit Step Count fetched manually: \(sumSteps)")
            } else {
                print("dbg HealthKit Step Count manual fetch failed.")
            }
        }
    }

    func stopMeasurement() {
        print("stop")
        self.statusText = "測定終了しました"
        LiveActivityManager.shared.stop()
        pedometerService.stopUpdates()
        locationService.stopUpdateLocation()
    }

    // MARK: - PedometerManagerDelegate (CoreMotion)
    func pedometerManager(_ manager: PedometerManager, didUpdateNumberOfSteps steps: NSNumber) {
        let newLogText = "\(steps) 歩"
        print("dbg CoreMotion steps \(steps)")

        LiveActivityManager.shared.update(steps: steps.intValue)

        DispatchQueue.main.async {
            self.cmLogText = newLogText
        }
    }

    func pedometerManager(_ manager: PedometerManager, didUpdateActivity activity: String) {
        print("dbg CoreMotion Activity: \(activity)")
        DispatchQueue.main.async {
            self.activityText = activity
        }
    }

    // MARK: - HealthKitManagerDelegate (HealthKit) ⬇️ 追加
    func healthKitManager(_ manager: HealthKitServiceType, didUpdateNumberOfSteps steps: Double) {
        let newLogText = "\(Int(steps)) 歩"
        print("dbg HealthKit steps \(steps)")

        DispatchQueue.main.async {
            self.hkLogText = newLogText
        }
    }

    func fetchLatestHealthKitSteps() {
        Task {
            let now = Date()
            let startOfDay = Calendar.current.startOfDay(for: now)

            if let sumSteps = await healthKitService.fetchStepCountSum(from: startOfDay, to: now) {
                self.healthKitManager(self.healthKitService, didUpdateNumberOfSteps: sumSteps)

                print("dbg HealthKit Step Count fetched automatically: \(sumSteps)")
            } else {
                print("dbg HealthKit Step Count automatic fetch failed.")
            }
        }
    }
}
