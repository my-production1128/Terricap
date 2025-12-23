//
//  LiveActivityLiveActivity.swift
//  LiveActivity
//
//  Created by 濱松未波 on 2025/11/28.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct StepTrackerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {

        var steps: Int
        var activityStatus: String
    }
    var title: String
}

struct LiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StepTrackerAttributes.self) { context in
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundColor(.green)
                    .font(.title)

                VStack(alignment: .leading) {
                    Text(context.attributes.title)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(context.state.activityStatus)
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.primary)

                    Text("\(context.state.steps) 歩")
                        .font(.title2)
                        .bold()
                }
                Spacer()
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.green)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("\(context.state.steps)", systemImage: "figure.walk")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.activityStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                }
            } compactLeading: {

                Image(systemName: "figure.walk")
                    .foregroundColor(.green)
            } compactTrailing: {
                Text("\(context.state.steps)")
            } minimal: {
                Image(systemName: "figure.walk")
                    .foregroundColor(.green)
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
        StepTrackerAttributes.ContentState(steps: 100, activityStatus: "ウォーキング中 🚶")
    }
}

#Preview("Notification", as: .content, using: StepTrackerAttributes.preview) {
   LiveActivityLiveActivity()
} contentStates: {
    StepTrackerAttributes.ContentState.count100
}
