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

        // 1) ownerships を取得（未占有判定 & 更新用）
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
            .eq("task_id", value: taskId)
            .limit(1)
            .execute()
            .value

        var currentOwnership = ownerships.first

        // 2) task_id 単位の「最新勝者」を ownership_histories から取得（ここが核）
        let latestHistory = try await fetchLatestHistory(
            locationId: locationId,
            taskId: taskId
        )

        // 3) 未占有（ownerships が存在しない）なら、まず ownerships を作る
        //    ※ 履歴は task_id 単位で判定するので、history はこの後の分岐で入れる
        if currentOwnership == nil {
            try await insertOwnership(
                locationId: locationId,
                userId: userId,
                taskId: taskId,
                scoreType: scoreType,
                scoreValue: scoreValue
            )
            
            let refreshed: [Ownership] = try await client
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
                    .eq("task_id", value: taskId)
                    .limit(1)
                    .execute()
                    .value

                currentOwnership = refreshed.first
        }

        // 4) task_id の履歴が無い = この task の初回占有
        guard let latest = latestHistory else {
            try await insertHistory(
                locationId: locationId,
                winnerUserId: userId,
                loserUserId: nil,
                taskId: taskId,
                scoreType: scoreType,
                scoreValue: scoreValue
            )

            // ownerships は「現在状態」を表すので、初回は insertOwnership 済み or 既存なら update
            if let currentOwnership {
                try await updateOwnership(
                    ownershipId: currentOwnership.id,
                    userId: userId,
                    taskId: taskId,
                    scoreType: scoreType,
                    scoreValue: scoreValue
                )
            }

            return .success
        }

        // 5) すでに自分が最新勝者（task_id 文脈）
        if latest.winner_user_id == userId {
            return .alreadyOwned
        }

        // 6) スコア不足（task_id 文脈の最新勝者と比較）
        if scoreValue <= latest.score_value {
            return .lose
        }

        // 7) 勝利（再占有）
        //    loser は「直前の勝者」になる（ここが今回のバグ修正点）
        try await insertHistory(
            locationId: locationId,
            winnerUserId: userId,
            loserUserId: latest.winner_user_id,
            taskId: taskId,
            scoreType: scoreType,
            scoreValue: scoreValue
        )

        // 8) ownerships の現在状態も更新する（勝ったときだけ）
        //    既に ownerships がある前提（無ければ上で insert 済み）
        let updatedOwnershipId: Int
        if let currentOwnership {
            updatedOwnershipId = currentOwnership.id
        } else {
            // 念のため（通常ここには来ない）
            let inserted: [Ownership] = try await client
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
                .eq("task_id", value: taskId)
                .limit(1)
                .execute()
                .value

            guard let fallback = inserted.first else {
                // ここに来るなら DB 側 insert が失敗している
                throw NSError(domain: "OwnershipRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "ownerships row not found after insert"])
            }
            updatedOwnershipId = fallback.id
        }

        try await updateOwnership(
            ownershipId: updatedOwnershipId,
            userId: userId,
            taskId: taskId,
            scoreType: scoreType,
            scoreValue: scoreValue
        )

        return .success
    }

    func fetchOwnedLocationIds(userId: UUID) async throws -> [Int] {
        struct Row: Decodable { let location_id: Int }

        //ここは後で検討かも（）
        let rows: [Row] = try await client
            .from("ownerships")
            .select("location_id")
            .eq("user_id", value: userId)
            .execute()
            .value

        return rows.map { $0.location_id }
    }

    func fetchOtherOwnedLocationIds(userId: UUID) async throws -> [Int] {
        struct Row: Decodable { let location_id: Int }

        let rows: [Row] = try await client
            .from("ownerships")
            .select("location_id")
            .neq("user_id", value: userId)
            .execute()
            .value

        return rows.map { $0.location_id }
    }
}

// MARK: - Private helpers
private extension OwnershipRepository {

    // ownership_histories から「この location + task の最新1件」を取る
    // loser 判定・スコア比較はこれを正とする
    func fetchLatestHistory(locationId: Int, taskId: Int) async throws -> OwnershipHistoryLite? {
        struct Row: Decodable {
            let winner_user_id: UUID
            let score_value: Int
            let created_at: Date
        }

        let rows: [Row] = try await client
            .from("ownership_histories")
            .select("winner_user_id, score_value, created_at")
            .eq("location_id", value: locationId)
            .eq("task_id", value: taskId)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        guard let r = rows.first else { return nil }
        return OwnershipHistoryLite(winner_user_id: r.winner_user_id, score_value: r.score_value, created_at: r.created_at)
    }

    struct OwnershipHistoryLite {
        let winner_user_id: UUID
        let score_value: Int
        let created_at: Date
    }

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
