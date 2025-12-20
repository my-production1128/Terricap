//  Created by 末廣月渚 on 2025/11/21.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager
    @AppStorage("isProfileSetup") private var isProfileSetup = false

    var body: some View {
        Group {
            if authManager.currentUser == nil {
                LoginView()

            } else if !isProfileSetup {
                AToZView()

            } else {
                MapView()
            }
        }
        .task {
            await authManager.refreshUser()
        }
    }
}

