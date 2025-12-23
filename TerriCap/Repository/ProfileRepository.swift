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

    func fetchProfile(userId: UUID) async throws -> Profile_Decodable? {
        let response = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()

        print("raw response:", String(data: response.data, encoding: .utf8) ?? "nil")

        do {
                let decoded = try JSONDecoder().decode([Profile_Decodable].self, from: response.data)
                print(" decoded success:", decoded)
                return decoded.first

            } catch let error as DecodingError {
                //  decode エラーを詳細に出す
                switch error {
                case .typeMismatch(let type, let context):
                    print("Type mismatch:", type)
                    print("codingPath:", context.codingPath)
                    print("debug:", context.debugDescription)

                case .valueNotFound(let type, let context):
                    print("Value not found:", type)
                    print("codingPath:", context.codingPath)
                    print("debug:", context.debugDescription)

                case .keyNotFound(let key, let context):
                    print("Key not found:", key)
                    print("codingPath:", context.codingPath)
                    print("debug:", context.debugDescription)

                case .dataCorrupted(let context):
                    print("Data corrupted")
                    print("codingPath:", context.codingPath)
                    print("debug:", context.debugDescription)

                @unknown default:
                    print("Unknown decoding error")
                }

                throw error
            }
    }

    
    // プロフィールを Supabase にupsert
    func upsertProfile(_ profile: Profile_Codable) async throws {
        try await client
            .from("profiles")
            .upsert(profile)
            .execute()
    }
}

