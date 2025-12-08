//
//  Models.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/11/22.
//

import Foundation
import CoreLocation

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

struct Profile: Decodable, Identifiable {
    let id: UUID
    let name: String
    let color: String
    let alphabet: String
    let total_spots: Int
}

struct TaskProgress: Decodable, Identifiable {
    let id: Int8
    let user_id: UUID
    let move_progress: Int8
    let spot_progress: Int8
}

struct OwnerShip: Decodable, Identifiable {
    let id: Int
    let user_id: UUID
    let task_id: Int
}

struct User: Identifiable {
    let id: String
    let email: String
}
