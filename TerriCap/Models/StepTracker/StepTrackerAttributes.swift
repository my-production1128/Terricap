//
//  StepTrackerAttributes.swift
//  LiveActivity
//
//  Created by 濱松未波 on 2025/11/28.
//

import ActivityKit
import Foundation

// アプリとウィジェットの両方で共有するデータモデル
public struct StepTrackerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var steps: Int
        var targetSteps: Int        // 目標歩数も追加すると進捗が出せます
        var distance: String        // 「170m」などの直線距離
        var activityStatus: String
    }
    var title: String
}
