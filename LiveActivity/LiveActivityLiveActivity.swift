//
//  LiveActivityLiveActivity.swift
//  LiveActivity
//
//  Created by 濱松未波 on 2025/11/28.
//

import ActivityKit
import WidgetKit
import SwiftUI

// 1. データの定義: 歩数（steps）を動的な状態として持つ
struct StepTrackerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // ここに更新されるデータ（歩数）を定義
        var steps: Int
    }

    // ここに固定データ（タイトルなど）を定義
    var title: String
}

// 2. ウィジェットのUI定義
struct LiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StepTrackerAttributes.self) { context in
            // ===========================================
            // A. ロック画面 / 通知バナーの表示
            // ===========================================
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundColor(.green)
                    .font(.title)

                VStack(alignment: .leading) {
                    Text(context.attributes.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(context.state.steps) 歩")
                        .font(.title2)
                        .bold()
                }
                Spacer()
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8)) // 背景色
            .activitySystemActionForegroundColor(Color.green) // システムボタンの色

        } dynamicIsland: { context in
            // ===========================================
            // B. Dynamic Islandの表示（iPhone 14 Pro以降）
            // ===========================================
            DynamicIsland {
                // 拡張表示（長押し時）
                DynamicIslandExpandedRegion(.leading) {
                    Label("\(context.state.steps)", systemImage: "figure.walk")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("計測中")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // 下部エリア
                }
            } compactLeading: {
                // コンパクト表示（左）
                Image(systemName: "figure.walk")
                    .foregroundColor(.green)
            } compactTrailing: {
                // コンパクト表示（右）
                Text("\(context.state.steps)")
            } minimal: {
                // 最小表示
                Image(systemName: "figure.walk")
                    .foregroundColor(.green)
            }
        }
    }
}

// プレビュー用の設定
extension StepTrackerAttributes {
    fileprivate static var preview: StepTrackerAttributes {
        StepTrackerAttributes(title: "今日のウォーキング")
    }
}

extension StepTrackerAttributes.ContentState {
    fileprivate static var count100: StepTrackerAttributes.ContentState {
        StepTrackerAttributes.ContentState(steps: 100)
    }
}

#Preview("Notification", as: .content, using: StepTrackerAttributes.preview) {
   LiveActivityLiveActivity()
} contentStates: {
    StepTrackerAttributes.ContentState.count100
}
