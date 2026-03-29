//
//  Ownership.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2026/02/26.
//

import Foundation

// MARK: - 取得用 (Select)
struct Ownership: Decodable {
    let id: Int
    let spot_id: Int
    let user_id: UUID
    let taskscore_id: Int
    let score_value: Int
    var occupied_count: Int?
    let occupied_at: Date
    let update_at: Date
}

struct OwnershipHistory: Encodable {
    let id: Int
    let spot_id: Int
    let winner_user_id: UUID
    let loser_user_id: UUID?
    let taskscore_id: Int
    let score_value: Int
    let created_at: String
}

struct OwnershipHistoryLite: Decodable {
    let winner_user_id: UUID
    let score_value: Int
    let created_at: Date
}

// MARK: - 送信用 (Insert / Update)
struct OwnershipInsert: Encodable {
    let spot_id: Int
    let user_id: UUID
    let taskscore_id: Int
    let score_value: Int
}

struct OwnershipUpdate: Encodable {
    let user_id: UUID
    let taskscore_id: Int
    let score_value: Int
    let update_at: Date
}

struct OwnershipHistoryInsert: Encodable {
    let spot_id: Int
    let winner_user_id: UUID
    let loser_user_id: UUID?
    let taskscore_id: Int
    let score_value: Int
}
