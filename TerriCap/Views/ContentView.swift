//  Created by 末廣月渚 on 2025/11/21.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager
    
    var body: some View {
        Group {
            if let currentUser = authManager.currentUser {
                MapView()
            } else {
                LoginView()
            }
        }
        .task { await authManager.refreshUser() }
    }
}
