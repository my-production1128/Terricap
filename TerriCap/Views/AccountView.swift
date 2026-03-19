//
//  AccountView.swift
//  TerriCap
//
//  Created by 濱松未波 on 2026/02/19.
//
import SwiftUI

struct AccountView: View {
    @Environment(AuthManager.self) private var authManager
    @StateObject private var profileViewModel = ProfileViewModel()

    // 編集用の状態
    @State private var nickname: String = ""
    @State private var alphabet: String = ""
    @State private var selectColor: Color = .red
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    let presetColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown, .gray, .black
    ]
    let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        Button {
            Task { await authManager.signOut() }
        } label: {
            Text("サインアウト")
                .frame(maxWidth: .infinity)
        }
    }

}

