//
//  ProfileRepository.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/12/11.
//

import Foundation
import Supabase

final class ProfileRepository {

    private let client = SupabaseManager.shared.client

    // プロフィールを Supabase にupsert
    func upsertProfile(_ profile: Profile_Codable) async throws {
        try await client
            .from("profiles")
            .upsert(profile)
            .execute()
    }
}
