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
    //地図が拡大されているからいらなくなるだろう
//    @State private var showMarker: Bool = false
//    private let zoomLevel: Double = 0.02
    private let cameraBounds = MapCameraBounds(maximumDistance: 2500)
    @State private var selectedLocation: Location? = nil
    @State var istargetLocation = false
    @State private var showingAlert: Bool = false
    
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
                                statusColor: mapItem.statusColor
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeOut(duration: 2.0)) {
                                    selectedLocation = location
                                    mapViewModel.position = .region(MKCoordinateRegion(
                                        center: location.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                    ))
                                }
                            }
                        }
//    ------------------以下ことはちゃん確認お願いします_01---------------------
//                ForEach(locationViewModel.items) { item in
//                    Annotation(item.name, coordinate: item.coordinate) {
//                        if showMarker{
//                            MarkerView(item: item)
//                                .contentShape(Rectangle())
//                                .onTapGesture{
//                                    withAnimation(.easeOut(duration: 2.0)) {
//                                        //                                    viewModel.setTargetLocation(item)
//                                        selectedLocation = item
//                                        mapViewModel.position = .region(MKCoordinateRegion(
//                                            center: item.coordinate,
//                                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
//                                        ))
//                                    }
//                                }
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
//        ------------------ここまで---------------------
                    }
                    .annotationTitles(.hidden)
                }
            }
            
//            .sheet(item: $selectedLocation){ item in
//                HalfModalView(item:item, viewModel: self.viewModel, istargetLocation: $istargetLocation)
//                    .presentationDetents([.fraction(0.45)])
//                    .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.45)))
//                    .presentationBackground(.clear)
//                    .presentationCornerRadius(55)
//            .onMapCameraChange{ context in
//                let currentSpan = context.region.span.latitudeDelta
//                withAnimation(.easeInOut(duration: 0.3)){
//                    showMarker = currentSpan < zoomLevel
//                }
//            }
            //    ------------------以下ことはちゃん確認お願いします_02---------------------
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
                //    ------------------ここまで---------------------
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
