//
//  MapViewModel.swift
//  TerriCap
//  Created by 友田采芭 on 2025/11/19.
//

import SwiftUI
import MapKit
import CoreLocation // CLLocationManager を使うために必要
import Combine
import Supabase

struct userProfile {
    var userAlphabet : String
    var userColor : Color
}
// final class はそのまま維持。NSObject を継承して CLLocationManagerDelegate を実装
final class MapViewModel: NSObject, ObservableObject {
    
    // CoreLocation を使用するためのマネージャ
    private let manager = CLLocationManager()
    private let client = SupabaseManager.shared.client
    private var realtimeChannel: RealtimeChannelV2?
    
    // 地図表示位置
    @Published var position: MapCameraPosition = .userLocation(fallback: .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 32.806241, longitude:  130.765460),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )))
    
    // 位置情報の許可ステータスを保持
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var cameraBounds: MapCameraBounds? = nil
    
    // イニシャライザで自身をデリゲートに設定し、権限をリクエストするメソッドを呼び出す
    override init() {
        super.init()
        manager.delegate = self
        // 権限ステータスの初期値を取得
        self.authorizationStatus = manager.authorizationStatus
        
        // ユーザーに位置情報使用の許可を求める
        checkAndRequestLocationPermission()
    }
    
    // 権限リクエストのメソッド
    func checkAndRequestLocationPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            // 権限がまだ決定されていない場合、リクエスト
            manager.requestWhenInUseAuthorization()
            
        case .authorizedWhenInUse, .authorizedAlways:
            // 権限がある場合、現在地を一度だけリクエスト
            manager.requestLocation()
            
        case .denied, .restricted:
            // 権限がない、または制限されている場合
            print("位置情報サービスへのアクセスが拒否されています。")
            // 必要に応じて、ユーザーに設定アプリへの誘導を促す
            
        @unknown default:
            break
        }
    }
}



// CLLocationManagerDelegateを実装
extension MapViewModel: CLLocationManagerDelegate {
    
    // 位置情報関連の権限に変更があったら呼び出される
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("\(#function): 権限ステータスが変更されました -> \(manager.authorizationStatus.rawValue)")
        self.authorizationStatus = manager.authorizationStatus
        
        // 権限が新しく許可された場合、現在地をリクエスト
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            print("\(#function): 権限が許可されたので、現在地をリクエストします。")
            
            // 継続的な更新ではなく、一度だけの取得を推奨
            manager.requestLocation()
            
        } else if manager.authorizationStatus == .notDetermined {
            // ここで再度リクエストするのは冗長なので、基本的には何もしない
            // `init()` またはユーザーアクションでリクエスト済み
            print("\(#function): 権限が未決定のため、リクエストはスキップします。")
        }
    }
    
    // 位置情報の取得に成功した際に呼び出される
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        // 取得した現在地に合わせて地図のカメラ位置を更新
        DispatchQueue.main.async {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            self.position = .region(region)
            let restrictionRegion = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 2500,
                longitudinalMeters: 2500
            )
            self.cameraBounds = MapCameraBounds(
                centerCoordinateBounds: restrictionRegion,
                maximumDistance: 3000
            )
        }
    }
    
    // 位置情報の取得に失敗した際に呼び出される
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置情報の取得エラー: \(error.localizedDescription)")
    }
}

extension StepViewModel {

    struct MapItem: Identifiable {
        let id: Int
        let name: String
        let coordinate: CLLocationCoordinate2D
        let occupyStatus: OccupyStatus

        var statusColor: Color {
            switch occupyStatus {
            case .ownedByMe: return .blue
            case .ownedByOther: return .red
            case .notOwned: return .gray
            }
        }
    }

    enum OccupyStatus {
        case ownedByMe
        case ownedByOther
        case notOwned
        
        var label: String {
            switch self {
            case .ownedByMe:    return "今このスポットはあなたが占有しています"
            case .ownedByOther: return "今このスポットは他の人が占有しています"
            case .notOwned:     return "今このスポットは誰のものでもありません"
            }
        }
    }
    
}
