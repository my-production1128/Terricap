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
    private var currentActivity: Activity<StepTrackerAttributes>?

    private init() {}

    // 1. アクティビティを開始する
    func start(initialSteps: Int, targetSteps: Int, distance: String, activityStatus: String) {
            if currentActivity != nil {
                stop()
            }

            let attributes = StepTrackerAttributes(title: "ウォーキング計測中")
            // activityStatus をセット
        let contentState = StepTrackerAttributes.ContentState(
                    steps: initialSteps,
                    targetSteps: targetSteps,
                    distance: distance,
                    activityStatus: activityStatus
                )

            do {
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
    func update(steps: Int, targetSteps: Int, distance: String, activityStatus: String) {
            guard let activity = currentActivity else { return }

            // activityStatus を更新
        let updatedState = StepTrackerAttributes.ContentState(
                    steps: steps,
                    targetSteps: targetSteps,
                    distance: distance,
                    activityStatus: activityStatus
                )

            Task {
                if #available(iOS 16.1, *) {
                    await activity.update(
                        ActivityContent(state: updatedState, staleDate: nil)
                    )
                    print("Live Activity Updated: \(steps), \(activityStatus)")
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
