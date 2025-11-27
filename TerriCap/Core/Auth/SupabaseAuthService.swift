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
    func signUp(email: String, password: String) async throws -> User {
        // supabase SDKのサインアップ関数、内部でHTTP POSTを行い、確認メール送信を行なっている
        let response = try await client.auth.signUp(email:email, password: password)
        
        // メールが取得できなければ、エラーを投げる
        guard let email = response.user.email else {
            print("DEBUG: No email")
            throw NSError()
        }
        print(response.user)
        
        return User(id: response.user.aud, email: email)
    }
    
    // サインイン関数・非同期で実行
    func signIn(email: String, password: String) async throws -> User {
        let response = try await client.auth.signIn(email:email, password: password)
        guard let email = response.user.email else {
            print("DEBUG: No email")
            throw NSError()
        }
        print(response.user)
        
        return User(id: response.user.aud, email: email)
    }
    
    // 単にSDKのsignOut関数を呼んでいる・成功したらsession/tokenは無効化
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    // ユーザーがすでにログインしているかどうか
    func getCurrentUser() async throws -> User? {
        let supabaseUser = try await client.auth.session.user
        
        guard let email = supabaseUser.email else {
            print("DEBUG: No email")
            throw NSError()
        }
        
        return User(id :supabaseUser.aud, email: email)
    }
    
    // googleを使った認証
//    func signInWithGoogle() async throws {
//        try await client.auth.signInWithOAuth(provider: .google)
//    }
}

