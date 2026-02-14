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
        }
    }
}

