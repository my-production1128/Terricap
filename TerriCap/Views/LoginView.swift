//
//  LoginView.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/11/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "figure.walk")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.blue)

            Text("TerriCap")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Apple IDでログインしてください")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            //  Sign in with Apple
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { _ in
                    // 実際の認証処理は Supabase が行うので
                    // ここでは何もしない
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 48)
            .padding(.horizontal, 32)
            .onTapGesture {
                signInWithApple()
            }

            Spacer()
        }
    }
}

private extension LoginView {
    func signInWithApple() {
        Task {
            await authManager.signInWithApple()
        }
    }
}
