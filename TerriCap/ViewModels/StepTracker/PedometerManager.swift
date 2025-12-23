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
    func pedometerManager(_ manager: PedometerManager, didUpdateActivity activity: String)
}

class PedometerManager: PedometerServiceType {

    private var pedometer: CMPedometer?
    private var activityManager: CMMotionActivityManager?
    weak var delegate: PedometerManagerDelegate?
    var numberOfSteps: NSNumber = 0

    // 【追加】センサーが稼働中かを管理するフラグ
    private var isUpdating: Bool = false
    // 【追加】計測開始基準日を固定（アプリ起動中はずっとここからの累積を数える）
    private let serviceStartDate = Date()

    static var shared = PedometerManager()
    private init() {

    }

    func startUpdates() {
        // 【修正】既に動いている場合は何もしない（センサーの再起動ラグ防止）
        if isUpdating {
            print("dbg already started (High Performance Mode)")
            return
        }

        if (pedometer == nil) {
            pedometer = CMPedometer()
        }

        if CMMotionActivityManager.isActivityAvailable() {
            activityManager = CMMotionActivityManager()
            startActivityUpdates()
        } else {
            print("dbg CMMotionActivityManager is not available.")
        }

        if (CMPedometer.isStepCountingAvailable()) {
            print("dbg isStepCountingAvailable")
            // numberOfSteps = 0 // 【削除】累積値をリセットしない

            isUpdating = true // フラグをオン

            // 【修正】固定した開始時間（serviceStartDate）から計測し続ける
            pedometer?.startUpdates(from: serviceStartDate) { [weak self] (data, error) in
                print("dbg update!")
                guard let self else {
                    return
                }
                if (error != nil) {
                    print("dbg \(error!.localizedDescription)")
                    return
                }
                guard let data else {
                    print("dbg data is nil")
                    return
                }
                let steps = data.numberOfSteps
                self.numberOfSteps = steps
                self.delegate?.pedometerManager(self, didUpdateNumberOfSteps: steps)
            }
        }
    }

    private func startActivityUpdates() {
        activityManager?.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            let activityString = self.activityToString(activity)
            self.delegate?.pedometerManager(self, didUpdateActivity: activityString)
        }
    }

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
        // 【修正】高性能化のため、停止メソッドが呼ばれてもセンサーは止めない。
        // これにより、次回の開始時にウォームアップ時間が不要になる。
        print("dbg stopUpdates requested but ignored for high performance")

        // 本当に完全に停止が必要な場合（アプリ終了時など）以外はコメントアウトまたは何もしない
        /*
        pedometer?.stopUpdates()
        pedometer = nil
        activityManager?.stopActivityUpdates()
        activityManager = nil
        isUpdating = false
        */
    }
}
