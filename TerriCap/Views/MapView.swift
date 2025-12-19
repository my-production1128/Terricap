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

    //地図が拡大されているからいらなくなるだろう
//    @State private var showMarker: Bool = false
//    private let zoomLevel: Double = 0.02
    private let cameraBounds = MapCameraBounds(maximumDistance: 2500)
    
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: StepViewModel
    @State var istargetLocation = false
    @State private var showingAlert: Bool = false
    
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
                                    withAnimation(.easeOut(duration: 2.0)) {
                                        //                                    viewModel.setTargetLocation(item)
                                        selectedLocation = item
                                        mapViewModel.position = .region(MKCoordinateRegion(
                                            center: item.coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                        ))
                                    }
                                }
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
                    }
                    .annotationTitles(.hidden)
                }
            }
//            .onMapCameraChange{ context in
//                let currentSpan = context.region.span.latitudeDelta
//                withAnimation(.easeInOut(duration: 0.3)){
//                    showMarker = currentSpan < zoomLevel
//                }
//            }
            .sheet(isPresented: Binding(
                get: {
                    selectedLocation != nil
                },
                set: {
                    if !$0 { selectedLocation = nil }
                }
            )){
                if let item = selectedLocation {
                    HalfModalView(item:item, viewModel: self.viewModel, istargetLocation: $istargetLocation)
                        .presentationDetents([.fraction(0.45)])
                        .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.45)))
                        .presentationBackground(.clear)
                        .presentationCornerRadius(55)
                        .id(item.id)
                        .transition(.identity)
                }
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
            if istargetLocation{
                VStack{
                    Spacer()
                    HStack{
                        Rectangle()
                            .fill(.white.opacity(0.9))
                            .frame(width: 135, height: 90)
                            .cornerRadius(30)
                            .overlay(
                                ZStack{
                                    ZStack{
                                        Text("歩数")
                                            .font(.caption)
                                        if viewModel.isTaskCleared {
                                            Image(systemName: "checkmark.seal.fill")
                                                .resizable()
                                                .frame(width: 20, height: 20)
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(.white, .yellow)
                                                .padding(.leading, 55)
                                        }
                                    }
                                    .padding(.bottom, 50)
                                    HStack {
                                        Text("\(viewModel.cmLogInt)")
                                            .font(.title)
                                            .bold()
                                            .padding(.bottom, 5)
                                        if let target = viewModel.targetSteps {
                                            Text("/\(target)")
                                                .font(.caption)
                                                .foregroundColor(.black)
                                        } else {
                                            Text("/目標未設定")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.top, 12)
                                }
                                    //.padding(.vertical, 20)
                            )
                            .padding(.vertical, 20)
                            .padding(.horizontal, 7)
                        Spacer()
                        Button(action: {
                            showingAlert.toggle()
                        }) {
                            Image(systemName: "stop.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .red)
                                .padding(14)
                            
                        }
                    }
                }
                
            }
        }
        .ignoresSafeArea(edges: [.bottom])
        .alert("確認", isPresented: $showingAlert){
            Button("いいえ", role: .cancel){}
            Button("はい"){
                istargetLocation = false
                viewModel.stopMeasurement()
            }
        } message: {
            Text("現在の測定内容を破棄しますか？")
        }

        
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
                                HStack{
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 38, height: 38)
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .yellow)
                                    Text("占有範囲に入りました (\(distanceText))")
                                        .font(.title2)
                                }
                            } else {
                                HStack{
                                    Image(systemName: "mappin.and.ellipse")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 43, height: 43)
                                        .foregroundStyle(.green)
                                    VStack(alignment: .leading){
                                        Text("\(targetName)まで")
                                            .font(.caption)
                                        Text("残り\(distanceText)")
                                            .font(.title3)
                                            .bold()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
