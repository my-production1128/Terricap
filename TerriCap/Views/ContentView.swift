//  Created by 末廣月渚 on 2025/11/21.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        NavigationStack {
            if authManager.currentUser == nil {
                LoginView()

            } else if !authManager.hasProfile {
                GameCenterConnectView()
            } else {
                MainTabView()
            }
        }
        .task {
            await authManager.refreshUser()
        }
    }
}


struct MainTabView: View {
    @State private var selectedTab: Tab = .map

    enum Tab {
        case map,
             stats,
             ranking,
             account
    }

    var body: some View {
        TabView {
            MapView()
                .tabItem {
                    Label("マップ", systemImage: "map.fill")
                }
                .tag(Tab.map)

            StatsView()
                .tabItem {
                    Label("実績", systemImage: "chart.bar.fill")
                }
                .tag(Tab.stats)
//ここにことはちゃんがチャラクターの画面追加する
//            CharacterView()
//                .tabItem {
//                    Label("キャラクター", systemImage: "crown.fill")
//                }
//                .tag(Tab.character)

            RankingView()
                .tabItem {
                    Label("ランキング", systemImage: "crown.fill")
                }
                .tag(Tab.ranking)

            AccountView()
                .tabItem {
                    Label("アカウント", systemImage: "person.crop.circle.fill")
                }
                .tag(Tab.account)
        }
    }
}

