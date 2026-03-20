//
//  Ownership.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2026/02/26.
//

import Foundation

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
