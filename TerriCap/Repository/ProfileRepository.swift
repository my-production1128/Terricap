//
//  ProfileRepository.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/12/11.
//

import Foundation
import Supabase

final class ProfileRepository {
    
    // SupabaseManagerからクライアントをもらう
    private let client = SupabaseManager.shared.client
    
    // MARK: - Fetch (取得)
        // Profile? (オプショナル) を返すように変更
        func fetchProfile(userId: UUID) async throws -> Profile? {
            // .optional() を使うと、データがない場合にエラーにならず nil が返ります
            let response: PostgrestResponse<Profile?> = try await client // Profile? にする
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single() // SDKのバージョンによっては .single() のままでOKな場合と .limit(1).single() が必要な場合があります
                .execute()
                
            // データがなければ nil、あれば Profile が返る
            return response.value
        }
    
    // MARK: - Update (更新)
        // Game Center ID を更新（または作成）する
    func updateGameCenterId(userId: UUID, gameCenterId: String) async throws {
        
        // 更新したいデータ
        // id も一緒に送ることで、行がない場合は insert になります（upsert）
        struct ProfileUpdate: Encodable {
            let id: UUID
            let game_center_id: String
            let updated_at: Date
        }
        
        let updateData = ProfileUpdate(
            id: userId,
            game_center_id: gameCenterId,
            updated_at: Date()
        )
        
        try await client
            .from("profiles")
            .upsert(updateData) // update ではなく upsert に変更！
            .execute()
        
        print("Repository: GameCenterIDを保存しました -> \(gameCenterId)")
    }
}
