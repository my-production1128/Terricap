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
        // 動的に更新されるデータ
        var steps: Int
    }

    // 固定データ
    var title: String
}
