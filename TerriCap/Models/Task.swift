//
//  Task.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2026/02/26.
//

import Foundation

struct ParkTask: Codable {
    var id: Int?
    var spot_id: Int
    var wlk: Int
    var point_value: Int
    let created_at: String
}

struct LocalTaskLog: Codable, Identifiable {
    var id = UUID()
    let startTime: Date
    let endTime: Date
    let steps: Int
    var isCalorieFetched: Bool = false
}
