//
//  Models.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/11/22.
//

import Foundation
import CoreLocation

// decodableは受信
struct Location: Decodable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let tasks: [TaskScore]?
    
    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
}

struct TaskScore: Decodable, Identifiable {
    let id: Int
    let location_id: Int
    let goal_move_value: Int
    let goal_spot_value: Int
    let goal_point_value: Int
    let created_at: String   // or Date
}

struct Profile: Codable, Identifiable {
    let id: UUID
    let game_center_id: String?
    let name: String?
    let created_at: Date
    let updated_at: Date
//    enum CodingKeys: String, CodingKey {
//        case id
//        case gameCenterId = "game_center_id"
//        case name
//    }
}

struct Ownership: Decodable {
    let id: Int
    let location_id: Int
    let user_id: UUID
    let task_id: Int
    let score_type: String
    let score_value: Int
    let occupied_at: Date
    let updated_at: Date
}

struct TaskProgress: Decodable, Identifiable {
    let id: Int8
    let user_id: UUID
    let move_progress: Int8
    let spot_progress: Int8
}

struct User: Identifiable {
    let id: String
    let email: String
}

struct OwnershipInsert: Encodable {
    let location_id: Int
    let user_id: UUID
    let task_id: Int
    let score_type: String
    let score_value: Int
    let occupied_at: Date
    let updated_at: Date
}

struct OwnershipUpdate: Encodable {
    let user_id: UUID
    let task_id: Int
    let score_type: String
    let score_value: Int
    let occupied_at: Date
    let updated_at: Date
}

struct OwnershipHistoryInsert: Encodable {
    let location_id: Int
    let winner_user_id: UUID
    let loser_user_id: UUID?
    let task_id: Int
    let score_type: String
    let score_value: Int
}

// Models.swift 等に追加
struct LocalTaskLog: Codable, Identifiable {
    var id = UUID()
    let startTime: Date
    let endTime: Date
    let steps: Int
    var isCalorieFetched: Bool = false
}

