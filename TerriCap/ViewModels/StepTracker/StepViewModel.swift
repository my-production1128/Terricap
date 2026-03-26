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
import SwiftUI

class StepViewModel: NSObject, ObservableObject, PedometerManagerDelegate, HealthKitManagerDelegate, LocationServiceDelegate {
    
    // MARK: - データ管理
    @Published var cmLogInt: Int = 0      // 現在の歩数
    @Published var targetSteps: Int? = nil    // 目標歩数
    @Published var isTaskCleared: Bool = false // クリアしたかどうかのフラグ
    
    @Published var activityText: String = "活動認識待機中..."
    @Published var hkLogText: String = "---"
    @Published var statusText: String = "測定待機中"

    @Published var currentLocation: CLLocation?
    @Published var targetLocation: ParkUploadData?
    @Published var occupyStatusText: String?
    // 占有状況把握のための以下三つ
    @Published var mapItems: [MapItem] = []
    @Published var ownedLocationIds: Set<Int> = []
    @Published var otherOwnedLocationIds: Set<Int> = []
    @Published var isOccupying: Bool = false // 通信中フラグ
    @Published var lastFetchedCalories: Double? = nil // 最新で取得できたカロリー
    @Published var showCalorieResult: Bool = false    // シート表示フラグ
    private var isCalorieResultShown = false

    private var realtimeTask: Task<Void, Never>?
    
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
    func setTargetLocation(_ location: ParkUploadData) {
        self.targetLocation = location
        self.isTaskCleared = false
        
        if let firstTask = location.taskscores?.first {
            let goal = firstTask.wlk
            self.targetSteps = goal
            print("目標設定: \(goal)歩")
        } else {
            // 万が一データがなかった場合の予備（2000歩）
            self.targetSteps = 2000
            print("目標歩数が設定されていません。デフォルトの2000歩を設定します。")
        }
        evaluateTaskCondition()
    }

    // MARK: - 測定開始
    func startMeasurement(target: ParkUploadData? = nil) {
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
        evaluateTaskCondition()
        LiveActivityManager.shared.start(initialSteps: 0,targetSteps: 0,distance: "", activityStatus: self.activityText)
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

                LiveActivityManager.shared.update(steps: displaySteps, targetSteps: self.targetSteps ?? 0, distance: self.distanceDisplayString ?? "", activityStatus: self.activityText)

                self.cmLogInt = displaySteps


                self.evaluateTaskCondition()
            }
        }
    }
    
    // MARK: - 達成判定ロジック
    private func evaluateTaskCondition(targetSteps: Int? = nil, distance: Double? = nil) {
        let effectiveTarget = targetSteps ?? self.targetSteps
        let _ = distance ?? self.rawDistanceToTarget

        guard let target = effectiveTarget else { return }

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
        DispatchQueue.main.async {
            self.activityText = activity

            if self.isMeasuring {
                LiveActivityManager.shared.update(steps: self.cmLogInt, targetSteps: self.targetSteps ?? 0, distance: self.distanceDisplayString ?? "", activityStatus: activity)
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
        // すでに占有処理が完了している、または現在通信中なら即座に抜ける
        guard !hasTriedOccupy && !isOccupying else { return }

        guard
            let ownershipRepository = ownershipRepository,
            let userId = currentUserId,
            let distance = rawDistanceToTarget,
            distance <= 300,
            isTaskCleared,
            let location = targetLocation,
            let task = location.taskscores?.first,
            let taskId = task.id
        else {
            return
        }

        let realLocationId = task.spot_id
        
        // ---- ここで即座にロックをかける ----
        isOccupying = true
        print("occupy try start: LocationID \(realLocationId), TaskID \(taskId)")

        Task {
            do {
                let result = try await ownershipRepository.tryOccupySpot(
                    spotId: realLocationId,
                    userId: userId,
                    taskscoreId: taskId,
                    scoreValue: cmLogInt
                )

                await MainActor.run {
                    // 通信完了。結果に応じて hasTriedOccupy を更新
                    handleOccupyResult(result)
                    isOccupying = false // ロック解除
                }
            } catch {
                await MainActor.run {
                    occupyStatusText = "通信エラーが発生しました"
                    print("occupy error:", error)
                    isOccupying = false // エラー時もロックを解除して再試行可能にする
                }
            }
        }
    }

    // 監視をスタートするためのメソッドを追加
    func startRealtimeObserver(locations: [ParkUploadData]) {
        // すでに監視中なら二重に走らないようにキャンセルする
        realtimeTask?.cancel()
        
        realtimeTask = Task { [weak self] in
            guard let self = self, let repository = self.ownershipRepository else { return }
            
            // リポジトリの監視機能を呼び出す
            await repository.listenForOwnershipChanges {
                Task {
                    print("誰かが陣地を更新しました！地図を再描画します。")
                    // 変更があったら、最新の占有状況を取り直して地図を更新
                    await self.refreshOwnershipStates(locations: locations)
                }
            }
        }
    }
    
    // 画面が消える時などに監視を止める用（オプション）
    func stopRealtimeObserver() {
        realtimeTask?.cancel()
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
    func refreshOwnershipStates(locations: [ParkUploadData]) async {
        guard
            let ownershipRepository,
            let userId = currentUserId
        else {
            print("ownershipRepository or userId is nil")
            return
        }

        do {
            async let myIds = ownershipRepository.fetchOwnedSpotIds(userId: userId)
            async let otherIds = ownershipRepository.fetchOtherOwnedSpotIds(userId: userId)

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
                locations: [ParkUploadData],
                ownedLocationIds: Set<Int>,
                otherOwnedLocationIds: Set<Int>
    ) {
        mapItems = locations.map { location in
            let status: OccupyStatus
            
            let spotId = location.taskscores!.first!.spot_id
            
            if ownedLocationIds.contains(spotId) {
                status = .ownedByMe    // 自分の陣地
            } else if otherOwnedLocationIds.contains(spotId) {
                status = .ownedByOther // 誰かの陣地
            } else {
                status = .notOwned     // 誰もいない
            }
            
            return MapItem(
                id: spotId,
                name: location.name,
                coordinate: location.coordinate,
                occupyStatus: status,
                park: location
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

