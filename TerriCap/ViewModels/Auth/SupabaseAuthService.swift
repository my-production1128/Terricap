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
   
    // サインアップ関数・非同期で実行
    func signUp(email: String, password: String) async throws {
        _ = try await client.auth.signUp(
            email: email,
            password: password
            )
    }
    
    // サインイン関数・非同期で実行
    func signIn(email: String, password: String) async throws -> Auth.User {
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        return response.user
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

