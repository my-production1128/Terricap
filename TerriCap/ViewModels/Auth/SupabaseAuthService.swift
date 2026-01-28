//
//  SupabaseAuthService.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/11/25.
//

import Foundation
import Supabase

struct SupabaseAuthService {
    
    // シングルトンからSDKのクライアントを取得？
    // このclientを通じてサインアップ、サインインを実行
    private let client = SupabaseManager.shared.client
    
    func signInWithApple() async throws -> Auth.User {
        try await client.auth.signInWithOAuth(
            provider: .apple
        )

        // OAuth完了後、現在のセッションから user を取得
        let session = try await client.auth.session
        return session.user
    }
    // 単にSDKのsignOut関数を呼んでいる・成功したらsession/tokenは無効化
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    // ユーザーがすでにログインしているかどうか
    func getCurrentUser() async throws -> Auth.User? {
            let session = try await client.auth.session
            return session.user
    }
}

