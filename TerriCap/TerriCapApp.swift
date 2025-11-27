//
//  TerriCapApp.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/11/21.
//

import SwiftUI

@main
struct TerriCapApp: App {
    @State private var authManager = AuthManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
        }
    }
}

