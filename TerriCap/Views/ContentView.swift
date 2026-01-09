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
