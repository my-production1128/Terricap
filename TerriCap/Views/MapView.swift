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
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @StateObject private var parkViewModel = ParkViewModel()
    // 現在地用（カメラ位置）
    @StateObject private var mapViewModel = MapViewModel()
    @StateObject private var viewModel: StepViewModel
    @Environment(AuthManager.self) private var authManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedPark: ParkUploadData? = nil
    @State var istargetLocation = false
    @State private var showingAlert: Bool = false
    
    init() {
        let vm = StepViewModel(
            pedometerService: PedometerManager.shared,
            locationService: LocationManager.shared,
            healthKitService: HealthKitManager.shared
        )

        self._viewModel = StateObject(wrappedValue: vm)
    }

    
    
    var body: some View {
        ZStack{
            Map(position: $mapViewModel.position, bounds: mapViewModel.cameraBounds) {
                
                // 現在地
                UserAnnotation {
                    if let profile = profileViewModel.profile {
                        
                        ZStack {
                            // 背景の装飾（必要に応じて）
                            Circle()
                                .fill(.white)
                                .frame(width: 40, height: 40)
                                .shadow(radius: 3)

                            // ここにGameCenterのアイコンを表示
                            // 仮に profileViewModel などで取得した画像を表示する場合
                            if let avatarImage = profileViewModel.avatarImage { // 取得済み画像がある場合
                                Image(uiImage: avatarImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                            } else {
                                // 画像がない場合のフォールバック（GameCenter風のデフォルトアイコン）
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 36, height: 36)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
                
                
                // Supabase から取得したピン
                ForEach(viewModel.mapItems) { item in
                    Annotation(item.name, coordinate: item.coordinate){
                        
                        MarkerView(
                            park: item.park, // 💡 元の公園データ
                            statusColor: item.occupyStatus.color // 🎨 陣地ごとの色！
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 2.0)) {
                                selectedPark = item.park // item.parkを使う
                                mapViewModel.position = .region(MKCoordinateRegion(
                                    center: item.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                ))
                            }
                        }
                    }
                    .annotationTitles(.hidden)
                }
            }
            .sheet(item: $selectedPark) { park in
                HalfModalView(
                    park: park,
                    occupy: "占有状況", // ★ひとまず仮置き
                    viewModel: self.viewModel,
                    istargetLocation: $istargetLocation
                )
                .presentationDetents([.fraction(0.45)])
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.45)))
                .presentationBackground(.clear)
                .presentationCornerRadius(55)
                .transition(.identity)
            }
            .ignoresSafeArea(edges: .bottom)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .task {
                // 1. 各種セットアップ
                mapViewModel.checkAndRequestLocationPermission()
                LocationManager.shared.setup()
                LocationManager.shared.startUpdateLocation()
                
                guard let userId = authManager.currentUserId else { return }
                profileViewModel.startGameCenterConnection()
                viewModel.configure(currentUserId: userId)
                viewModel.setup()
                
                // 2. 現在地の取得を少し待つ（LocationManagerの起動待ち）
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待つ
                
                if let userCoord = LocationManager.shared.locationManger.location?.coordinate {
                    // 周辺の公園を検索 → Supabaseに保存 → 最新の公園リストを取得
                    await parkViewModel.searchAndSaveParks(at: userCoord)
                } else {
                    print("DEBUG: まだ現在地が取得できていません")
                    // 位置情報が取れなくても、とりあえずDBに入っている公園は表示しておく
                    await parkViewModel.fetchParks()
                }
                
                // 4. その他の更新処理
                await viewModel.refreshOwnershipStates(locations: parkViewModel.parks)
                viewModel.startRealtimeObserver(locations: parkViewModel.parks)
                await profileViewModel.fetchProfile()
                await viewModel.checkAndSyncCalories()
                await profileViewModel.refreshAvatar()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    print("dbg App came to foreground. Fetching latest HealthKit steps.")
                    viewModel.fetchLatestHealthKitSteps()
                    
                    Task {
                        await profileViewModel.refreshAvatar()
                    }
                }
            }
            .ignoresSafeArea(edges: [.bottom])


            if istargetLocation {
                VStack{
                    HStack{
                        Text("歩数")
                            .font(.caption)
                            .padding(.leading, 10)
                        if viewModel.isTaskCleared {
                            Image(systemName: "checkmark.seal.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .yellow)
                                .padding(.leading, 55)
                        }
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
                        Spacer()
                    }

                    if let distanceText = viewModel.distanceDisplayString,
                       let targetName = viewModel.targetLocation?.name {
                        HStack{
                            if let rawDist = viewModel.rawDistanceToTarget, rawDist <= 150 {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 38, height: 38)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .yellow)
                                Text("占有範囲に入りました (\(distanceText))")
                                    .font(.headline)
                            } else {
                                HStack{
                                        Text("\(targetName)まで")
                                            .font(.caption)
                                            .padding(.leading, 10)
                                        Text("\(distanceText)")
                                            .font(.title3)
                                            .bold()
                                }
                            }
                            Spacer()
                        }
                    }
                    Spacer()
                    Button(action: {
                        showingAlert.toggle()
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .red)
                            .padding(20)

                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showCalorieResult) {
            if let calories = viewModel.lastFetchedCalories {
                CalorieResultSheet(targetCalories: calories)
                    .presentationDetents([.medium]) // 半分の高さで表示
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
    }
}
