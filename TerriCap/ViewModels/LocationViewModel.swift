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
    @Published var items: [MapItem] = []
    @Published var error: String?

    func fetchLocations() async {
        do {
            let response: PostgrestResponse<[Location]> = try await SupabaseManager.shared.client
                .from("locations")
                .select()
                .execute()
            
            print("Supabase response:", response.value)

            let locations = response.value

            self.items = locations.map { location in
                MapItem(
                    id: UUID(),
                    coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    )
                )
            }
            
            print("MapItems:", self.items)

        } catch {
            self.error = error.localizedDescription
            print("fetchLocations error:", error)
        }
    }
}
