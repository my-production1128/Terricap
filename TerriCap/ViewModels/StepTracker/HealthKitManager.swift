//
//  HealthKitManager.swift
//  step tracker
//
//  Created by 濱松未波 on 2025/11/19.
//
import HealthKit

class HealthKitManager: HealthKitServiceType {

    private let healthStore = HKHealthStore()
    private let stepCountType = HKSampleType.quantityType(forIdentifier: .stepCount)!

    // リアルタイムクエリを保持
    private var liveQuery: HKObserverQuery?

    weak var delegate: HealthKitManagerDelegate?

    static var shared = HealthKitManager()
    private init() {

    }

    // MARK: - 権限リクエスト
    func requestAuthorization() async throws {
        let typesToRead: Set<HKObjectType> = [stepCountType]
        try await healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: typesToRead)
    }

    // MARK: - リアルタイム歩数更新の開始
    func startStepCountUpdates() {
        // 既存のクエリがあれば停止・クリア
        if let query = liveQuery {
            healthStore.stop(query)
            liveQuery = nil
        }

        // 1. HKObserverQueryを設定
        // バックグラウンドでデータ更新を監視
        let observerQuery = HKObserverQuery(sampleType: stepCountType, predicate: nil) { [weak self] _, completionHandler, error in

            guard let self = self else { return }

            if let error = error {
                print("HealthKit Observer Query Error: \(error.localizedDescription)")
                completionHandler()
                return
            }

            // 2. 更新が通知されたら、HKAnchoredObjectQueryで最新データを取得
            self.fetchTodayStepCount { steps in
                if let steps = steps {
                    // リアルタイムの歩数をデリゲートに通知
                    self.delegate?.healthKitManager(self, didUpdateNumberOfSteps: steps)
                }
                completionHandler() // 処理完了をHealthKitに通知
            }
        }

        healthStore.execute(observerQuery)
        // 初回実行をトリガー
        healthStore.enableBackgroundDelivery(for: stepCountType, frequency: .hourly) { success, error in
            if !success {
                print("Failed to enable background delivery: \(error?.localizedDescription ?? "unknown")")
            }
        }
        liveQuery = observerQuery

        // 初回データを取得・表示
        fetchTodayStepCount { steps in
            if let steps = steps {
                self.delegate?.healthKitManager(self, didUpdateNumberOfSteps: steps)
            }
        }
    }

    // リアルタイム表示用に「今日の合計歩数」を取得するヘルパーメソッド
    // HealthKitManager.swift 内の修正

    private func fetchTodayStepCount(completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        let now = Date()

        // ⬇️ 修正: guard let ではなく、let を使用して非オプショナルな Date を受け取る
        let startOfDay = calendar.startOfDay(for: now)

        // startOfDayは確定でDate型であるため、guard let は不要
        // （元のguard letブロック内の completion(nil) も削除）

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(
            quantityType: stepCountType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum // 合計値を取得
        ) { _, result, error in

            if let error = error {
                print("HealthKit Statistics Query Error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            let sum = result?.sumQuantity()?.doubleValue(for: .count())
            completion(sum)
        }

        healthStore.execute(query)
    }

    // MARK: - 既存の履歴歩数を取得 (ご提供いただいた非同期コード)
    func fetchStepCountSum(from startDate: Date, to endDate: Date) async -> Double? {
        // 提供されたコードのロジック
        let quantityType = HKSampleType.quantityType(forIdentifier: .stepCount)!
        let periodPredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate
        )
        let predicate = HKSamplePredicate.quantitySample(
            type: quantityType,
            predicate: periodPredicate
        )
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: predicate,
            options: .cumulativeSum // 合計値
        )

        do {
            let sum = try await descriptor.result(for: healthStore)?
                .sumQuantity()?
                .doubleValue(for: .count())
            return sum
        } catch {
            print("HealthKit fetchStepCountSum Error: \(error.localizedDescription)")
            return nil
        }
    }
}
