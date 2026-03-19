//
//  LiveActivityLiveActivity.swift
//  LiveActivity
//
//  Created by 濱松未波 on 2025/11/28.
//

import ActivityKit
import WidgetKit
import SwiftUI

public struct StepTrackerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var steps: Int
        var targetSteps: Int        // 目標歩数も追加すると進捗が出せます
        var distance: String        // 「170m」などの直線距離
        var activityStatus: String
    }
    var title: String
}

struct LiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StepTrackerAttributes.self) { context in
            // --- ロック画面の通知デザイン ---
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.red)
                        .font(.title3)
                    Text("進行中")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(context.state.activityStatus)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Label("歩数", systemImage: "figure.walk")
                            .font(.caption)
                            .foregroundColor(.gray)
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(context.state.steps)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            Text("/ \(context.state.targetSteps)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Label("目的地まで", systemImage: "location.north.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(context.state.distance)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }

                // 進捗バー
                ProgressView(value: Double(context.state.steps), total: Double(context.state.targetSteps))
                    .tint(.blue)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.9))

        } dynamicIsland: { context in
            // --- ダイナミックアイランドのデザイン ---
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Label("\(context.state.steps)", systemImage: "figure.walk")
                            .font(.title2.bold())
                            .foregroundColor(.blue)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(context.state.distance)
                            .font(.title2.bold())
                            .foregroundColor(.green)
                        Text("残り距離")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: Double(context.state.steps), total: Double(context.state.targetSteps))
                        .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "figure.walk").foregroundColor(.blue)
            } compactTrailing: {
                Text(context.state.distance).foregroundColor(.green).bold()
            } minimal: {
                Image(systemName: "target").foregroundColor(.red)
            }
        }
    }
}

extension StepTrackerAttributes {
    fileprivate static var preview: StepTrackerAttributes {
        StepTrackerAttributes(title: "今日のウォーキング")
    }
}

extension StepTrackerAttributes.ContentState {
    fileprivate static var count100: StepTrackerAttributes.ContentState {
        StepTrackerAttributes.ContentState(steps: 100, targetSteps: 1000, distance: "170m", activityStatus: "ウォーキング中 🚶")
    }
}

#Preview("Notification", as: .content, using: StepTrackerAttributes.preview) {
   LiveActivityLiveActivity()
} contentStates: {
    StepTrackerAttributes.ContentState.count100
}

