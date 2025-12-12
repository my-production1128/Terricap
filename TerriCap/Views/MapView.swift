//
//  MapView.swift
//  TerriCap
//  Created by 友田采芭 on 2025/11/19.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    // 現在地用（カメラ位置）
    @StateObject private var mapViewModel = MapViewModel()
    // Supabase のピン
    @StateObject private var locationViewModel = LocationViewModel()
    @Environment(AuthManager.self) private var authManager

    @State private var selectedLocation: Location? = nil
//<<<<<<< HEAD
//    @State private var showMarker: Bool = false
//
//    private let zoomLevel: Double = 0.02
//    private let cameraBounds = MapCameraBounds(maximumDistance: 2500)

    //    歩数計用(steptracker)
//=======
    //地図が拡大されているからいらなくなるだろう
//    @State private var showMarker: Bool = false
//    private let zoomLevel: Double = 0.02
    private let cameraBounds = MapCameraBounds(maximumDistance: 2500)
    
//    歩数計用(steptracker)
//>>>>>>> dev
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: StepViewModel
    @State var istargetLocation = false

    init() {
        _locationViewModel = StateObject(wrappedValue: LocationViewModel())
        
        let pedometer = PedometerManager.shared
        let location = LocationManager.shared
        let healthKit = HealthKitManager.shared
        let vm = StepViewModel(
            pedometerService: pedometer,
            locationService: location,
            healthKitService: healthKit
        )

        self._viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        ZStack{
            Map(position: $mapViewModel.position, bounds: cameraBounds) {
                UserAnnotation{
                    ZStack{
                        //🦪🐸
                        Circle()
                            .fill(.orange)
                            .frame(width: 31, height: 31)
                            .shadow(radius: 3)
                        Circle()
                            .fill(.white.opacity(0.8))
                            .frame(width: 25, height: 25)
                        Text("A")
                            .foregroundStyle(.orange)
                            .font(.system(size: 20))
                    }
                }
                ForEach(locationViewModel.items) { item in
                    Annotation(item.name, coordinate: item.coordinate) {
//                        if showMarker{
                            MarkerView(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture{
                                    //                                    viewModel.setTargetLocation(item)
                                    selectedLocation = item
                                }
//<<<<<<< HEAD
//                        } else {
//                            Circle()
//                            //                                .fill(item.statusColor)
//                                .frame(width: 15, height: 15)
//                                .overlay(
//                                    Circle()
//                                        .stroke(.white, lineWidth: 2)
//                                )
//                                .transition(.scale.combined(with: .opacity))
//                                .onTapGesture{
//                                    //                                    viewModel.setTargetLocation(item)
//                                    selectedLocation = item
//                                }
//                        }
//=======
//                        } else {
//                           Circle()
////                                .fill(item.statusColor)
//                                .frame(width: 15, height: 15)
//                                .overlay(
//                                    Circle()
//                                        .stroke(.white, lineWidth: 2)
//                                )
//                                .transition(.scale.combined(with: .opacity))
//                                .onTapGesture{
//                                    selectedLocation = item
//                                }
//                        }
//>>>>>>> dev
                    }
                }
            }
//            .onMapCameraChange{ context in
//                let currentSpan = context.region.span.latitudeDelta
//                withAnimation(.easeInOut(duration: 0.3)){
//                    showMarker = currentSpan < zoomLevel
//                }
//            }
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

                Task {
                    await locationViewModel.fetchLocations()
                }
                viewModel.setup()
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
