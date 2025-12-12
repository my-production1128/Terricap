//  Created by 末廣月渚 on 2025/11/21.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager
    @AppStorage("isProfileSetup") private var isProfileSetup = false
    
    // デバッグ用：後で消す
    private let debugResetProfile = true
    
    var body: some View {
        Group {
            if authManager.currentUser != nil {

                if !isProfileSetup {
                    AToZView()
                } else {
                    MapView()
                }

            } else {
                LoginView()
            }
        }
        .task {
            if debugResetProfile { // 後で消す
                isProfileSetup = false
            }
            await authManager.refreshUser()
        }
    }
}
