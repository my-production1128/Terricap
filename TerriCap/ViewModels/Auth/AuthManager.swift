//
//  AuthManager.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/11/25.
//

import Foundation
import Observation

@Observable
@MainActor //これ使ったらメインで動かしますよってこと
class AuthManager{ // Viewとサーバーの橋渡し役・currentUserを管理
    // 実際にsupabaseにアクセス・Login,SignUp,SignOutの実行担当
    private let authService: SupabaseAuthService
    
    // 現在ログインしているユーザーを保持する場所
    // Optional(?)の理由はログインしていない状態(nil)があるため
    var currentUser: User?
    
    // デフォルト値設定・初期化時にサービスを渡す
    init(authService: SupabaseAuthService = SupabaseAuthService()) {
        self.authService = authService
    }
    
    // サインアップ機能
    // ユーザー作成・成功したらcurrentUserを更新・失敗したらエラー表示
    func signUp(email: String, password: String) async {
        do{
            self.currentUser = try await authService.signUp(email: email, password: password)
        } catch {
            print("DEBUG: Sign up error: \(error.localizedDescription)")
        }
    }
    // サインイン機能
    // ログインチェック・成功したらcurrentUserにユーザーをセット
    func signIn(email: String, password: String) async {
        do{
            self.currentUser = try await authService.signIn(email: email, password: password)
        } catch {
            print("DEBUG: Sign in error: \(error.localizedDescription)")
        }
    }
    
    // ログアウト機能
    // ログアウト・currentUserをnilにする・ログアウトしたらUI更新
    func signOut() async {
        do{
            try await authService.signOut()
            currentUser = nil
        } catch {
            print("DEBUG: Sign out error: \(error.localizedDescription)")
        }
    }
    
    // ログイン状態を維持しているか確認するための関数
    // アプリを閉じたか次の日に起動したかなどの結果を反映してマップ画面かログイン画面下の判断に使う
    func refreshUser() async {
        do {
            self.currentUser = try await authService.getCurrentUser()
        } catch {
            print("Refresh user error: \(error)")
            currentUser = nil
        }
    }
}
