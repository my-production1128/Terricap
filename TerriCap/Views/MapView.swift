//
//  MapView.swift
//  TerriCap
//  Created by 友田采芭 on 2025/11/19.
//

import SwiftUI
import MapKit

struct MapView: View {
    // 現在地用（カメラ位置）
    @StateObject private var mapViewModel = MapViewModel()
    // Supabase のピン
    @StateObject private var locationViewModel = LocationViewModel()
    @Environment(AuthManager.self) private var authManager
    
    var body: some View {
        Map(position: $mapViewModel.position) {
            
            ForEach(locationViewModel.items) { item in
                Annotation(item.id.uuidString, coordinate: item.coordinate) {
                    MakerView(item: item)
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onAppear {
            mapViewModel.checkAndRequestLocationPermission()

            Task {
                await locationViewModel.fetchLocations()
            }
        }
        .ignoresSafeArea(edges: [.bottom])
        
        Button {
            Task {
                await authManager.signOut()
            }
        } label: {
            Text("サインアウト")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 120, height: 40)
                .background(Color.blue)
                .cornerRadius(8)
                .padding()
        }
    }
}


