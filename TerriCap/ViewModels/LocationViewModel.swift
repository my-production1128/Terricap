//
//  LocationViewModel.swift
//  TerriCap
//  Created by 末廣月渚 on 2025/11/20.
//
import Foundation
import SwiftUI
import Combine

//@MainActor
final class LocationViewModel: ObservableObject {
    @Published var items: [Location] = []
    @Published var error: String?
    
    private let repository: LocationRepository

    init(repository: LocationRepository = LocationRepository()) {
        self.repository = repository
    }

    func fetchLocations() async {
        do {
            let locations = try await repository.fetchLocations()
            self.items = locations
        } catch {
            self.error = error.localizedDescription
            print("fetchLocations error:", error)
        }
    }
}
