//
//  PedometerManager.swift
//  step tracker
//
//  Created by 濱松未波 on 2025/11/18.
//
import UIKit
import CoreMotion

protocol PedometerManagerDelegate: AnyObject {
    func pedometerManager(_ manager: PedometerManager, didUpdateNumberOfSteps steps: NSNumber)
    // ⬇️ 追加: 活動認識の更新メソッド
    func pedometerManager(_ manager: PedometerManager, didUpdateActivity activity: String)
}

class PedometerManager: PedometerServiceType {

    private var pedometer: CMPedometer?
    private var activityManager: CMMotionActivityManager?
    weak var delegate: PedometerManagerDelegate?
    var numberOfSteps: NSNumber = 0

    static var shared = PedometerManager()
    private init() {

    }

    func startUpdates() {
            if (pedometer == nil) {
                pedometer = CMPedometer()
            } else {
                print("dbg already started")
                return
            }

            // ⬇️ 追加: activityManagerの初期化と活動認識の開始
            if CMMotionActivityManager.isActivityAvailable() {
                activityManager = CMMotionActivityManager()
                startActivityUpdates()
            } else {
                print("dbg CMMotionActivityManager is not available.")
            }
            // ⬆️ ここまで追加

            if (CMPedometer.isStepCountingAvailable()) {
                print("dbg isStepCountingAvailable")
                numberOfSteps = 0

                pedometer?.startUpdates(from: Date()) { [weak self] (data, error) in
                    print("dbg update!")
                    guard let self else {
                        return
                    }
                    // ... (既存の歩数更新ロジック)
                    if (error != nil) {
                        print("dbg \(error!.localizedDescription)")
                        return
                    }
                    guard let data else {
                        print("dbg data is nil")
                        return
                    }
                    let steps = data.numberOfSteps
                    numberOfSteps = steps
                    self.delegate?.pedometerManager(self, didUpdateNumberOfSteps: steps)
                }
            }
        }

    private func startActivityUpdates() {
            activityManager?.startActivityUpdates(to: .main) { [weak self] activity in
                guard let self = self, let activity = activity else { return }

                // 認識された活動を取得し、文字列に変換
                let activityString = self.activityToString(activity)

                // デリゲート経由でViewModelに通知
                self.delegate?.pedometerManager(self, didUpdateActivity: activityString)
            }
        }

        // ⬇️ 新規追加: CMMotionActivityから活動を表す文字列を生成するヘルパーメソッド
        private func activityToString(_ activity: CMMotionActivity) -> String {
            if activity.walking {
                return "ウォーキング中 🚶"
            } else if activity.running {
                return "走行中 🏃"
            } else if activity.cycling {
                return "サイクリング中 🚴"
            } else if activity.automotive {
                return "車両移動中 🚗"
            } else if activity.stationary {
                return "静止中 🧍"
            } else if activity.unknown {
                return "不明"
            }
            return "認識なし"
        }

        func stopUpdates() {
            if (pedometer == nil && activityManager == nil) { // ⬇️ activityManagerのチェックを追加
                return
            }

            pedometer?.stopUpdates()
            pedometer = nil

            // ⬇️ 追加: 活動認識の更新を停止
            activityManager?.stopActivityUpdates()
            activityManager = nil
        }
}

