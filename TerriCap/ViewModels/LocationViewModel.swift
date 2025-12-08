//
//  LocationViewModel.swift
//  TerriCap
//  Created by 末廣月渚 on 2025/11/20.
//
import Foundation
import Supabase
import CoreLocation
import SwiftUI
import Combine

@MainActor
class LocationViewModel: ObservableObject {
    @Published var items: [Location] = []
    @Published var error: String?
    
    func fetchLocations() async {
        do {
            let response: PostgrestResponse<[Location]> = try await SupabaseManager.shared.client
                .from("locations")
                .select("""
                    id,
                    name,
                    latitude,
                    longitude,
                    tasks:tasks(*)
                """)

                .execute()
            
            self.items = response.value
            print("Locations:", self.items)
            
        } catch {
            self.error = error.localizedDescription
            print("fetchLocations error:", error)
        }
    }
}
