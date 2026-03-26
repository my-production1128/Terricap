//
//  OwnershipRepository.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/12/19.
//

import Foundation
import Supabase

// ユーザーがスポットを奪おうとした時のアクション定義
protocol OwnershipRepositoryType {
    func tryOccupySpot(
        spotId: Int,
        userId: UUID,
        taskscoreId: Int,
        scoreValue: Int
    ) async throws -> OccupyResult // 戻り値
    
    func fetchOwnedSpotIds(userId: UUID) async throws -> [Int] // 自分の陣地リストの取得
    func fetchOtherOwnedSpotIds(userId: UUID) async throws -> [Int] // 他人の陣地リストの取得
    func listenForOwnershipChanges(onChanged: @escaping () -> Void) async
}

final class OwnershipRepository: OwnershipRepositoryType {
    
    static let shared = OwnershipRepository(
        client: SupabaseManager.shared.client
    )
    
    private let client: SupabaseClient
    
    private init(client: SupabaseClient) {
        self.client = client
    }
    
    func tryOccupySpot(
        spotId: Int,
        userId: UUID,
        taskscoreId: Int,
        scoreValue: Int
    ) async throws -> OccupyResult {
        
        // 1) 現在の占有状況を取得 (Helperを使用)
        var currentOwnership = try await fetchOwnership(spotId: spotId, taskscoreId: taskscoreId)
        
        // 2) 最新勝者を履歴から取得 (既存Helper)
        let latestHistory = try await fetchLatestHistory(spotId: spotId, taskscoreId: taskscoreId)
        
        // 3) 未占有なら新規作成
        if currentOwnership == nil {
            try await insertOwnership(spotId: spotId, userId: userId, taskscoreId: taskscoreId, scoreValue: scoreValue)
            // 再取得もHelperで1行！
            currentOwnership = try await fetchOwnership(spotId: spotId, taskscoreId: taskscoreId)
        }
        
        // 4) 履歴が無い = このタスクの初回占有
        guard let latest = latestHistory else {
            try await insertHistory(
                spotId: spotId,
                winnerUserId: userId,
                loserUserId: nil,
                taskscoreId: taskscoreId,
                scoreValue: scoreValue
            )
            
            if let currentOwnership {
                try await updateOwnership(
                    ownershipId: currentOwnership.id,
                    userId: userId,
                    taskscoreId: taskscoreId,
                    scoreValue: scoreValue
                )
            }
            return .success
        }
        
        // 5) すでに自分が最新勝者
        if latest.winner_user_id == userId {
            return .alreadyOwned
        }
        
        // 6) スコア不足
        if scoreValue <= latest.score_value {
            return .lose
        }
        
        // 7) 勝利（再占有）
        try await insertHistory(
            spotId: spotId,
            winnerUserId: userId,
            loserUserId: latest.winner_user_id,
            taskscoreId: taskscoreId,
            scoreValue: scoreValue
        )
        
        // 8) 最終的な更新処理
        guard let ownershipId = currentOwnership?.id else {
            throw NSError(domain: "OwnershipRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Data lost"])
        }
        
        try await updateOwnership(ownershipId: ownershipId, userId: userId, taskscoreId: taskscoreId, scoreValue: scoreValue)
        
        return .success
    }
    
    func fetchOwnedSpotIds(userId: UUID) async throws -> [Int] {
        struct Row: Decodable { let spot_id: Int }
        
        let rows: [Row] = try await client
            .from("ownerships")
            .select("spot_id")
            .eq("user_id", value: userId) // eqは「＝」自分自身のIDと一致するデータを探す
            .execute()
            .value
        
        return rows.map { $0.spot_id }
    }
    
    func fetchOtherOwnedSpotIds(userId: UUID) async throws -> [Int] {
        struct Row: Decodable { let spot_id: Int }
        
        let rows: [Row] = try await client
            .from("ownerships")
            .select("spot_id")
            .neq("user_id", value: userId) // neqは「not＝」自分以外のIDを持つデータを探す
            .execute()
            .value
        
        return rows.map { $0.spot_id } // .mapを使って中身のspot_idだけを取り出す
    }
    
    func listenForOwnershipChanges(onChanged: @escaping () -> Void) async {
        // ownershipsテーブル専用のチャンネル（通信路）を作る
        let channel = client.channel("public:ownerships")
        
        // publicスキーマのownershipsテーブルで起きる全てのアクション（追加・更新）を監視
        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "ownerships"
        )
        
        // 監視スタート！
        do {
            try await channel.subscribeWithError()
        } catch {
            print("エラー：失敗しました:", error)
            return
        }
        
        // 変更が飛んでくるたびに、このループが回って ViewModel に知らせる
        for await _ in changes {
            print("Supabaseからリアルタイム通知を受信しました")
            onChanged()
        }
    }
}

// MARK: - Private helpers
private extension OwnershipRepository {
    
    // 指定したスポットとタスクの現在の占有状況を取得する
    private func fetchOwnership(spotId: Int, taskscoreId: Int) async throws -> Ownership? {
        let ownerships: [Ownership] = try await client
            .from("ownerships")
            .select("""
                    id, spot_id, user_id, taskscore_id, score_value,
                    occupied_count, occupied_at, update_at
                    """)
            .eq("spot_id", value: spotId)
            .eq("taskscore_id", value: taskscoreId)
            .limit(1)
            .execute()
            .value
        return ownerships.first
    }
    
    // 最新の勝者を特定
    func fetchLatestHistory(spotId: Int, taskscoreId: Int) async throws -> OwnershipHistoryLite? {
        let rows: [OwnershipHistoryLite] = try await client
            .from("ownerships_histories")
            .select("winner_user_id, score_value, created_at")
            .eq("spot_id", value: spotId)
            .eq("taskscore_id", value: taskscoreId)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        
        return rows.first
    }
    
    //新しい占有データを登録
    func insertOwnership(
        spotId: Int,
        userId: UUID,
        taskscoreId: Int,
        scoreValue: Int
    ) async throws {
        let model = OwnershipInsert(
            spot_id: spotId,
            user_id: userId,
            taskscore_id: taskscoreId,
            score_value: scoreValue
        )
        
        try await client
            .from("ownerships")
            .insert(model)
            .execute()
    }
    
    // 占有を上書き
    func updateOwnership(
        ownershipId: Int,
        userId: UUID,
        taskscoreId: Int,
        scoreValue: Int
    ) async throws {
        let model = OwnershipUpdate(
            user_id: userId,
            taskscore_id: taskscoreId,
            score_value: scoreValue,
            update_at: Date()
        )
        
        try await client
            .from("ownerships")
            .update(model)
            .eq("id", value: ownershipId)
            .execute()
    }
    
    func insertHistory(
        spotId: Int,
        winnerUserId: UUID,
        loserUserId: UUID?,
        taskscoreId: Int,
        scoreValue: Int
    ) async throws {
        let model = OwnershipHistoryInsert(
            spot_id: spotId,
            winner_user_id: winnerUserId,
            loser_user_id: loserUserId,
            taskscore_id: taskscoreId,
            score_value: scoreValue
        )
        
        try await client
            .from("ownerships_histories")
            .insert(model)
            .execute()
    }
}

