//
//  MapView.swift
//  TerriCap
//  Created by 友田采芭 on 2025/11/19.
//

import SwiftUI
import MapKit
import CoreLocation
import Supabase

struct MapView: View {
    // 現在地用（カメラ位置）
    @StateObject private var mapViewModel = MapViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    // Supabase のピン
    @StateObject private var locationViewModel = LocationViewModel()
    @StateObject private var viewModel: StepViewModel
    @Environment(AuthManager.self) private var authManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedLocation: Location? = nil
    private let cameraBounds = MapCameraBounds(maximumDistance: 2500)
    @State var istargetLocation = false
    
    init() {
        _locationViewModel = StateObject(wrappedValue: LocationViewModel())

        let vm = StepViewModel(
            pedometerService: PedometerManager.shared,
            locationService: LocationManager.shared,
            healthKitService: HealthKitManager.shared
        )

        self._viewModel = StateObject(wrappedValue: vm)
    }

    
    
    var body: some View {
        ZStack{
            Map(position: $mapViewModel.position, bounds: cameraBounds) {
                
                // 現在地
                UserAnnotation {
                    if let profile = profileViewModel.profile {
                        let color = Color.colorFromName(profile.color)
                        let alphabet = profile.alphabet

                        ZStack {
                            // 外側の丸
                            Circle()
                                .fill(color)
                                .frame(width: 31, height: 31)
                                .shadow(radius: 3)

                            // 内側の白丸
                            Circle()
                                .fill(Color.white)
                                .frame(width: 25, height: 25)

                            // アルファベット
                            Text(alphabet.uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(color)
                        }
                    }
                }


                // Supabase から取得したピン
                ForEach(viewModel.mapItems) { mapItem in
                    Annotation(mapItem.name, coordinate: mapItem.coordinate) {

                        if let location = locationViewModel.items.first(where: { $0.id == mapItem.id }) {

                            MarkerView(
                                item: location,
                                statusColor: mapItem.statusColor   // ← ここがポイント
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedLocation = location
                            }
                        }
                    }
                }
            }
            
            .sheet(item: $selectedLocation){ item in
                HalfModalView(item:item, viewModel: self.viewModel, istargetLocation: $istargetLocation)
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
                guard let userId = authManager.currentUserId else { return }

                viewModel.configure(currentUserId: userId)
                viewModel.setup()

                Task {
                    await locationViewModel.fetchLocations()
                    await profileViewModel.fetchProfile()

                    let locations = locationViewModel.items
                    await viewModel.refreshOwnershipStates(locations: locations)
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    print("dbg App came to foreground. Fetching latest HealthKit steps.")
                    viewModel.fetchLatestHealthKitSteps()
                }
            }
            .ignoresSafeArea(edges: [.bottom])
            
            VStack{
                HStack{
//🦪🐸県大付近を表示するボタン　あとで消す
//                    Button{
//                        mapViewModel.position = .region(MKCoordinateRegion(
//                            center: CLLocationCoordinate2D(latitude: 32.806241, longitude: 130.765460), // 県大
//                            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
//                        ))
//                    }label: {
//                        Image(systemName: "mappin.circle.fill")
//                            .resizable()
//                            .frame(width: 40, height: 40)
//                            .foregroundStyle(.blue)
//                            .background(Color.white)
//                            .cornerRadius(30)
//                    }
//                    .padding()

                    VStack {
                        Text("歩数")
                            .font(.subheadline)
                        Text("\(viewModel.cmLogInt)")
                            .font(.largeTitle)
                            .bold()
                    }
                    Button(action: {
                        istargetLocation = false
                        viewModel.stopMeasurement()
                    }) {
                        Text("測定停止")
                            .padding()
                    }.buttonStyle(.bordered)

                    if let target = viewModel.targetSteps {
                        Text("目標歩数：\(target)")
                            .font(.headline)
                            .foregroundColor(.black)
                    } else {
                        Text("(目標未設定)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }


                    Spacer()
                }
                Spacer()
            }

        }
        .ignoresSafeArea(edges: [.bottom])

        HStack{
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
            if istargetLocation {
                VStack{
                    if let distanceText = viewModel.distanceDisplayString,
                       let targetName = viewModel.targetLocation?.name {
                        VStack(spacing: 4) {
                            if let rawDist = viewModel.rawDistanceToTarget, rawDist <= 150 {
                                Text("占有範囲に入りました (\(distanceText))")
                            } else {
                                Text("現在地から\(targetName)まで \(distanceText)")
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.9))
                                .shadow(radius: 3)
                        )
                    }
                    if viewModel.isTaskCleared {
                        Text("タスク条件クリア！🎉")
                            .font(.headline)
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
    }
}

extension Color {
    static func colorFromName(_ name: String) -> Color {
        switch name.lowercased() {
        case "red":      return .red
        case "orange":   return .orange
        case "yellow":   return .yellow
        case "green":    return .green
        case "teal":     return .teal
        case "cyan":     return .cyan
        case "blue":     return .blue
        case "indigo":   return .indigo
        case "purple":   return .purple
        case "pink":     return .pink
        case "brown":    return .brown
        case "gray":     return .gray
        case "black":    return .black
        default:
            return .orange
        }
    }
}
