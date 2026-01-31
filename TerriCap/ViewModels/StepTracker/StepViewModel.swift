//
//  StepViewModel.swift
//  step tracker
//
//  Created by 濱松未波 on 2025/11/19.
//
import Foundation
import Combine
import CoreLocation
import Supabase

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
    @Published var occupyStatusText: String?
    // 占有状況把握のための以下三つ
    @Published var mapItems: [MapItem] = []
    @Published var ownedLocationIds: Set<Int> = []
    @Published var otherOwnedLocationIds: Set<Int> = []

    @Published var lastFetchedCalories: Double? = nil // 最新で取得できたカロリー
    @Published var showCalorieResult: Bool = false    // シート表示フラグ
    private var isCalorieResultShown = false

    private var initialOffset: Int = 0
    private var rawTotalSteps: Int = 0
    private var isMeasuring: Bool = false

    private var taskStartTime: Date?

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
    
    private let pedometerService: PedometerServiceType
    private let locationService: LocationServiceType
    private let healthKitService: HealthKitServiceType
 
    private var ownershipRepository: OwnershipRepositoryType?
    private var currentUserId: UUID?
    private var hasTriedOccupy = false
    

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
    
    func configure(currentUserId: UUID) {
        self.currentUserId = currentUserId
        self.ownershipRepository = OwnershipRepository.shared
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

    
    // MARK: - 目標設定 (Startボタン押下時に呼ばれる想定)
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
        stopMeasurement()
        hasTriedOccupy = false
        if let location = target {
            self.setTargetLocation(location)
        }
        print("測定開始")
        self.statusText = "測定中"
        self.isMeasuring = true
        self.initialOffset = self.rawTotalSteps
        self.cmLogInt = 0
        self.taskStartTime = Date()
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
        finalizeTaskAndSaveLocally()

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
        // ---- デバッグログ ----
        print("---- checkOccupyStatus ----")
        print("rawDistance:", rawDistanceToTarget ?? -1)
        print("isTaskCleared:", isTaskCleared)
        print("hasTriedOccupy:", hasTriedOccupy)
        print("currentUserId:", currentUserId as Any)
        print("targetLocation:", targetLocation as Any)
        
        // ---- 二重実行防止 ----
        if hasTriedOccupy {
            return
        }
        
        // ---- 占有可能かの前提条件 ----
        guard
            let ownershipRepository,
            let userId = currentUserId,
            let distance = rawDistanceToTarget,
            distance <= 150,
            isTaskCleared,
            let location = targetLocation,
            let task = location.tasks?.first
        else {
            print("guard failed (not ready to occupy)")
            return
        }
        
        // ---- 状態確定 ----
        print("occupy try start")
        
        // ---- 占有処理 ----
        Task {
            do {
                let result = try await ownershipRepository.tryOccupyLocation(
                    locationId: location.id,
                    userId: userId,
                    taskId: task.id,
                    scoreType: "steps",
                    scoreValue: cmLogInt
                )
                
                await MainActor.run {
                    handleOccupyResult(result)
                }
            } catch {
                await MainActor.run {
                    occupyStatusText = "通信エラーが発生しました"
                    print("occupy error:", error)
                }
            }
        }
    }
    
    @MainActor
    private func handleOccupyResult(_ result: OccupyResult) {
        switch result {
        case .success:
            occupyStatusText = "スポットを占有しました！"
            hasTriedOccupy = true
            print("占有できています")
            
        case .alreadyOwned:
            occupyStatusText = "すでに占有しています"
            hasTriedOccupy = true
            print("既に占有してます")
            
        case .lose:
            occupyStatusText = "歩数が足りません"
            hasTriedOccupy = false
            print("歩数が足りません（再挑戦可）")
        }
    }
    
    @MainActor
    func refreshOwnershipStates(locations: [Location]) async {
        guard
            let ownershipRepository,
            let userId = currentUserId
        else {
            print("ownershipRepository or userId is nil")
            return
        }

        do {
            async let myIds = ownershipRepository.fetchOwnedLocationIds(userId: userId)
            async let otherIds = ownershipRepository.fetchOtherOwnedLocationIds(userId: userId)

            let (owned, otherOwned) = try await (myIds, otherIds)

            ownedLocationIds = Set(owned)
            otherOwnedLocationIds = Set(otherOwned)

            buildMapItems(
                locations: locations,
                ownedLocationIds: ownedLocationIds,
                otherOwnedLocationIds: otherOwnedLocationIds
            )
        } catch {
            print("failed to refresh ownership states:", error)
        }
    }

    
    func buildMapItems(
        locations: [Location],
        ownedLocationIds: Set<Int>,
        otherOwnedLocationIds: Set<Int>
    ) {
        mapItems = locations.map { location in
            let status: OccupyStatus

            if ownedLocationIds.contains(location.id) {
                status = .ownedByMe
            } else if otherOwnedLocationIds.contains(location.id) {
                status = .ownedByOther
            } else {
                status = .notOwned
            }

            return MapItem(
                id: location.id,
                name: location.name,
                coordinate: location.coordinate,
                occupyStatus: status
            )
        }
    }

    // --- ローカル保存と集計ロジック ---
    private func finalizeTaskAndSaveLocally() {
            guard let start = taskStartTime else { return }
            let end = Date()

            // 1. 累計歩数を更新してUserDefaultsに保存
            let currentTotalSteps = UserDefaults.standard.integer(forKey: "total_steps_all_time")
            UserDefaults.standard.set(currentTotalSteps + self.cmLogInt, forKey: "total_steps_all_time")

            // 2. カロリー取得待ちリスト（ログ）を保存
            let newLog = LocalTaskLog(startTime: start, endTime: end, steps: self.cmLogInt)
            var logs = fetchLocalLogs()
            logs.append(newLog)
            saveLocalLogs(logs)

            // クリア
            taskStartTime = nil
        }

        // 12時間経過した過去のタスクからカロリーを取得
    func checkAndSyncCalories() async {

        if isCalorieResultShown { return }

        var logs = fetchLocalLogs()
        let now = Date()
        var updated = false
        var newlyFetchedTotal: Double = 0.0 // 今回の同期で合計いくら取得できたか

        for i in 0..<logs.count {
            if !logs[i].isCalorieFetched && now.timeIntervalSince(logs[i].endTime) >= 10800 {
                if let calories = await HealthKitManager.shared.fetchActiveCalories(from: logs[i].startTime, to: logs[i].endTime) {
                    let currentCal = UserDefaults.standard.double(forKey: "total_calories_all_time")
                    UserDefaults.standard.set(currentCal + calories, forKey: "total_calories_all_time")

                    logs[i].isCalorieFetched = true
                    updated = true
                    newlyFetchedTotal += calories // 取得分を加算
                }
            }
        }

        if updated {
            saveLocalLogs(logs)
            // メインスレッドでUIを更新
            await MainActor.run {
                self.lastFetchedCalories = newlyFetchedTotal
                self.showCalorieResult = true // シートを表示
                self.isCalorieResultShown = true
            }
        } else {
            // デバッグ用：取得できるデータがなくても0として表示する（完成時はここを消す）
            await MainActor.run {
                self.lastFetchedCalories = 0.0
                self.showCalorieResult = true
                self.isCalorieResultShown = true
            }
        }
    }

        // ヘルパーメソッド
        private func fetchLocalLogs() -> [LocalTaskLog] {
            guard let data = UserDefaults.standard.data(forKey: "pending_task_logs"),
                  let decoded = try? JSONDecoder().decode([LocalTaskLog].self, from: data) else { return [] }
            return decoded
        }

        private func saveLocalLogs(_ logs: [LocalTaskLog]) {
            if let encoded = try? JSONEncoder().encode(logs) {
                UserDefaults.standard.set(encoded, forKey: "pending_task_logs")
            }
        }
}
