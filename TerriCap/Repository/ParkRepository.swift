//
//  GetParkPlacement.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2026/02/13.
//
import Foundation
import MapKit
import Supabase

class ParkRepository {
    static let shared = ParkRepository()
    private init() {}
    
    private let client = SupabaseManager.shared.client

    // LocationManagerから直接呼ばれるおまとめメソッド
    func searchAndSave(at coordinate: CLLocationCoordinate2D) {
        Task {
            do {
                print("公園の検索を開始します...")
                // 1. 地図から公園を検索
                let parks = try await searchParksFromMap(at: coordinate)
                
                // 2. 見つかったらSupabaseに保存
                if !parks.isEmpty {
                    try await saveParks(parks)
                    print("\(parks.count)件の公園データをSupabaseに保存・更新しました！")
                } else {
                    print("近くに公園が見つかりませんでした。")
                }
            } catch {
                print("公園の検索・保存中にエラーが発生しました: \(error)")
            }
        }
    }

    // 1. 地図から公園を検索
    func searchParksFromMap(at coordinate: CLLocationCoordinate2D) async throws -> [ParkUploadData] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "公園"
        let radius: CLLocationDistance = 300
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )
        
        let response = try await MKLocalSearch(request: request).start()
        
        return response.mapItems.compactMap { item in
            guard let name = item.name else { return nil }
            let location = item.location
            
            return ParkUploadData(
                name: name,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                place_id: item.identifier?.rawValue ?? "id_\(name)_\(location.coordinate.latitude)"
            )
        }
    }

    // 2. Supabaseからデータを取得
    func fetchSavedParks() async throws -> [ParkUploadData] {
        let parks: [ParkUploadData] = try await client
            .from("spots")
            .select("*, taskscores(*)")
            .execute()
            .value
        
        return parks
    }
    
    // 3. Supabaseに保存
    func saveParks(_ parks: [ParkUploadData]) async throws {
        try await client
            .from("spots")
            .upsert(parks, onConflict: "place_id")
            .execute()
    }
}
