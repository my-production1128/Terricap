//
//  OwnershipRepository.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/12/19.
//

import Foundation
import Supabase

protocol OwnershipRepositoryType {
    func tryOccupyLocation(
        locationId: Int,
        userId: UUID,
        taskId: Int,
        scoreType: String,
        scoreValue: Int
    ) async throws -> OccupyResult
    
    func fetchOwnedLocationIds(userId: UUID) async throws -> [Int]
    func fetchOtherOwnedLocationIds(userId: UUID) async throws -> [Int]
}

final class OwnershipRepository: OwnershipRepositoryType {

    static let shared = OwnershipRepository(
            client: SupabaseManager.shared.client
    )

    private let client: SupabaseClient

    private init(client: SupabaseClient) {
        self.client = client
    }

    func tryOccupyLocation(
        locationId: Int,
        userId: UUID,
        taskId: Int,
        scoreType: String,
        scoreValue: Int
    ) async throws -> OccupyResult {

        // 現在の占有情報を取得
        let response = try await client
            .from("ownerships")
            .select("""
                id,
                location_id,
                user_id,
                task_id,
                score_type,
                score_value,
                occupied_at,
                updated_at
            """)
            .eq("location_id", value: locationId)
            .limit(1)
            .execute()

        let ownerships: [Ownership] = try await client
            .from("ownerships")
            .select("""
                id,
                location_id,
                user_id,
                task_id,
                score_type,
                score_value,
                occupied_at,
                updated_at
            """)
            .eq("location_id", value: locationId)
            .limit(1)
            .execute()
            .value

        let current = ownerships.first


        // 未占有
        if current == nil {
            try await insertOwnership(
                locationId: locationId,
                userId: userId,
                taskId: taskId,
                scoreType: scoreType,
                scoreValue: scoreValue
            )

            try await insertHistory(
                locationId: locationId,
                winnerUserId: userId,
                loserUserId: nil,
                taskId: taskId,
                scoreType: scoreType,
                scoreValue: scoreValue
            )

            return .success
        }

        // ③ すでに自分が占有
        if current!.user_id == userId {
            return .alreadyOwned
        }

        // ④ スコア不足
        if scoreValue <= current!.score_value {
            return .lose
        }

        // ⑤ 奪取
        try await updateOwnership(
            ownershipId: current!.id,
            userId: userId,
            taskId: taskId,
            scoreType: scoreType,
            scoreValue: scoreValue
        )

        try await insertHistory(
            locationId: locationId,
            winnerUserId: userId,
            loserUserId: current!.user_id,
            taskId: taskId,
            scoreType: scoreType,
            scoreValue: scoreValue
        )

        return .success
    }
    
    func fetchOwnedLocationIds(userId: UUID) async throws -> [Int] {
        struct Row: Decodable {
            let location_id: Int
        }

        let rows: [Row] = try await client
            .from("ownerships")
            .select("location_id")
            .eq("user_id", value: userId)
            .execute()
            .value

        return rows.map { $0.location_id }
    }

    func fetchOtherOwnedLocationIds(userId: UUID) async throws -> [Int] {
        struct Row: Decodable {
            let location_id: Int
        }

        let rows: [Row] = try await client
            .from("ownerships")
            .select("location_id")
            .neq("user_id", value: userId)
            .execute()
            .value

        return rows.map { $0.location_id }
    }
}

private extension OwnershipRepository {

    func insertOwnership(
        locationId: Int,
        userId: UUID,
        taskId: Int,
        scoreType: String,
        scoreValue: Int
    ) async throws {

        let model = OwnershipInsert(
            location_id: locationId,
            user_id: userId,
            task_id: taskId,
            score_type: scoreType,
            score_value: scoreValue,
            occupied_at: Date(),
            updated_at: Date()
        )

        try await client
            .from("ownerships")
            .insert(model)
            .execute()
    }

    func updateOwnership(
        ownershipId: Int,
        userId: UUID,
        taskId: Int,
        scoreType: String,
        scoreValue: Int
    ) async throws {

        let model = OwnershipUpdate(
            user_id: userId,
            task_id: taskId,
            score_type: scoreType,
            score_value: scoreValue,
            occupied_at: Date(),
            updated_at: Date()
        )

        try await client
            .from("ownerships")
            .update(model)
            .eq("id", value: ownershipId)
            .execute()
    }

    func insertHistory(
        locationId: Int,
        winnerUserId: UUID,
        loserUserId: UUID?,
        taskId: Int,
        scoreType: String,
        scoreValue: Int
    ) async throws {

        let model = OwnershipHistoryInsert(
            location_id: locationId,
            winner_user_id: winnerUserId,
            loser_user_id: loserUserId,
            task_id: taskId,
            score_type: scoreType,
            score_value: scoreValue
        )

        try await client
            .from("ownership_histories")
            .insert(model)
            .execute()
    }
}
