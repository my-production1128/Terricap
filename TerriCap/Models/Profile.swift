//
//  Profile.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2026/02/26.
//

import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    let game_center_id: String?
    let name: String?
    let created_at: Date
    let updated_at: Date
    let first_value: Double
    let second_value: Double
}
