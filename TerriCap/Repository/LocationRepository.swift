//
//  LocationRepository.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/12/10.
//

import Foundation
import Supabase

final class LocationRepository {
    
    private let client = SupabaseManager.shared.client
    
    func fetchLocations() async throws -> [Location] {
        let response = try await client
            .from("locations")
            .select("""
                id,
                name,
                latitude,
                longitude,
                created_at,
                tasks(*)
            """)
            .execute()

        // response.data が JSON データ
        let data = response.data

        // JSON をデコード
        let locations = try JSONDecoder().decode([Location].self, from: data)

        return locations
    }
}
