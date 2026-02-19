//
//  GetParkPlacement.swift
//  TerriCap
//
//  Created by すさきひとむ on 2026/02/13.
//

import Foundation

import Foundation
import MapKit
import Supabase

class ParkSearchService {
    // シングルトンとしてどこからでも呼べるようにする
    static let shared = ParkSearchService()
    
    private init() {}
    
    // ★ 外から座標を投げ込むためのメインメソッド
    func searchAndSave(at coordinate: CLLocationCoordinate2D) {
        print("DEBUG: 公園検索を開始しました。 座標: \(coordinate.latitude), \(coordinate.longitude)")
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "公園"
        request.resultTypes = .pointOfInterest
        
        let radius: CLLocationDistance = 300// 1km
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            
            if let error = error {
                print("DEBUG: MapKit検索エラー: \(error.localizedDescription)")
                return
            }
            
            guard let response = response else {
                print("DEBUG: レスポンスが空です")
                return
            }
            
            print("DEBUG: 検索ヒット数: \(response.mapItems.count)件")
            
            
            let centerLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            let parks = response.mapItems.compactMap { item -> ParkUploadData? in
                guard let name = item.name,
                      let itemLocation = item.placemark.location else { return nil }
                
                // 距離フィルタリング
                if itemLocation.distance(from: centerLocation) > radius { return nil }
                
                // IDの取得
                let placeID = item.identifier?.rawValue ?? "id_\(item.placemark.coordinate.latitude)_\(item.placemark.coordinate.longitude)"
                
                return ParkUploadData(
                    name: name,
                    latitude: item.placemark.coordinate.longitude,
                    longitude: item.placemark.coordinate.latitude,
                    place_id: placeID,
                    
                )
            }
            
            if !parks.isEmpty {
                print("DEBUG: Supabaseへの送信準備完了 (\(parks.count)件)")
                Task {
                    await self.uploadToSupabase(parks: parks)
                }
            }
        }
    }
    
    private func uploadToSupabase(parks: [ParkUploadData]) async {
        print("DEBUG:Supabaseへアップロードを開始します...")
        do {
            try await SupabaseManager.shared.client
                .from("spots")
            //onConflictで重複を避ける印をつける
                .upsert(parks, onConflict: "place_id")
                .execute()
            print("Successfully saved \(parks.count) parks to Supabase.")
        } catch {
            print("Supabase Upload Error: \(error.localizedDescription)")
            dump(error)
        }
    }
}
