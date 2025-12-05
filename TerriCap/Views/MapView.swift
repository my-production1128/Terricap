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
    @State private var selectedLocation: MapItem? = nil
    @State private var showMarker: Bool = false
    private let zoomLevel: Double = 0.02
    private let cameraBounds = MapCameraBounds(maximumDistance: 2500)
    
    var body: some View {
        ZStack{
            Map(position: $mapViewModel.position, bounds: cameraBounds) {
                ForEach(locationViewModel.items) { item in
                    Annotation(item.id.uuidString, coordinate: item.coordinate) {
                        if showMarker{
                            MarkerView(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture{
                                    selectedLocation = item
                                }
                        } else {
                           Circle()
                                .fill(item.statusColor)
                                .frame(width: 15, height: 15)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 2)
                                )
                                .transition(.scale.combined(with: .opacity))
                                .onTapGesture{
                                    selectedLocation = item
                                }
                        }
                    }
                }
            }
            .onMapCameraChange{ context in
                let currentSpan = context.region.span.latitudeDelta
                withAnimation(.easeInOut(duration: 0.3)){
                    showMarker = currentSpan < zoomLevel
                }
            }
            .sheet(item: $selectedLocation){ item in
                HalfModalView(location: item)
                    .presentationDetents([.fraction(0.45)])
                    .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.45)))
                    .presentationBackground(.clear)
                    .presentationCornerRadius(55)
            }
            .ignoresSafeArea(edges: .bottom)
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
            //🦪🐸県大付近を表示するボタン　あとで消す
            VStack{
                HStack{
                    Button{
                        mapViewModel.position = .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: 32.806241, longitude: 130.765460), // 県大
                            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                        ))
                    }label: {
                        Image(systemName: "mappin.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue)
                            .background(Color.white)
                            .cornerRadius(30)
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
            }
            
        }
        .ignoresSafeArea(edges: [.bottom])
        
        VStack{
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
}
