//
//  LiveActivityManager.swift
//  LiveActivity
//
//  Created by 濱松未波 on 2025/11/28.
//

import Foundation
import ActivityKit

// アプリ本体側でLive Activityを操作するためのクラス
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    // 現在のアクティビティを保持する変数
    private var currentActivity: Activity<StepTrackerAttributes>?

    private init() {}

    // 1. アクティビティを開始する
    func start(initialSteps: Int) {
        // すでに実行中のものがあれば終了する（重複防止）
        if currentActivity != nil {
            stop()
        }

        // 表示するデータの初期状態
        let attributes = StepTrackerAttributes(title: "ウォーキング計測中")
        let contentState = StepTrackerAttributes.ContentState(steps: initialSteps)

        do {
            // iOS 16.1以降でのみ実行
            if #available(iOS 16.1, *) {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: contentState, staleDate: nil)
                )
                self.currentActivity = activity
                print("Live Activity Started: \(activity.id)")
            }
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }

    // 2. 歩数を更新する
    func update(steps: Int) {
        guard let activity = currentActivity else { return }

        let updatedState = StepTrackerAttributes.ContentState(steps: steps)

        Task {
            if #available(iOS 16.1, *) {
                await activity.update(
                    ActivityContent(state: updatedState, staleDate: nil)
                )
                print("Live Activity Updated: \(steps)")
            }
        }
    }

    // 3. アクティビティを終了する
    func stop() {
        guard let activity = currentActivity else { return }

        let finalState = activity.content.state // 最後の状態を維持

        Task {
            if #available(iOS 16.1, *) {
                // immediate: 即座に消す, default: ロック画面にしばらく残る
                await activity.end(
                    ActivityContent(state: finalState, staleDate: nil),
                    dismissalPolicy: .immediate
                )
                print("Live Activity Ended")
                self.currentActivity = nil
            }
        }
    }
}
