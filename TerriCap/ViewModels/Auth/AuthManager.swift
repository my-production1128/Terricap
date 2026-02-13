//
//  AuthManager.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/11/25.
//
import Foundation
import Observation
import Supabase

@Observable
@MainActor
class AuthManager {
    
    private let authService: SupabaseAuthService
    
    // 認証ユーザーは Supabase.Auth.User だけ
    var currentUser: Auth.User?
    
    var hasProfile: Bool = false
    
    // 占有や DB 用に使う UUID
    var currentUserId: UUID? {
        return currentUser?.id
    }
    
    init(authService: SupabaseAuthService = SupabaseAuthService()) {
        self.authService = authService
    }
    
    // MARK: - Sign in with Apple
    func signInWithApple() async {
        do {
            self.currentUser = try await authService.signInWithApple()
            print("signed in with apple:", currentUser?.id ?? "nil")
            
            if currentUser != nil {
                await checkProfile()
            }
        } catch {
            print("signInWithApple error:", error)
        }
    }

    // MARK: - Sign Out
    func signOut() async {
        do {
            try await authService.signOut()
            self.currentUser = nil
        } catch {
            print("signOut error:", error)
        }
    }
    
    // MARK: - Refresh User（起動時）
    func refreshUser() async {
        do {
            self.currentUser = try await authService.getCurrentUser()
            print("refreshed user:", currentUser?.id ?? "nil")
            
            if currentUser != nil {
                await checkProfile()
            } else {
                hasProfile = false
            }
        } catch {
            print("refreshUser error:", error)
            self.currentUser = nil
            hasProfile = false
        }
    }
    
    private func checkProfile() async {
        guard let userId = currentUser?.id else {
            hasProfile = false
            return
        }
        
        // 判定用に game_center_id を受け取る構造体
        struct ProfileCheck: Decodable {
            let game_center_id: String?
        }
        
        do {
            // game_center_id 列だけを取得する
            let rows: [ProfileCheck] = try await SupabaseManager.shared.client
                .from("profiles")
                .select("game_center_id") // idではなくこちらを取得
                .eq("id", value: userId)
                .limit(1)
                .execute()
                .value
            
            if let profile = rows.first, profile.game_center_id != nil {
                // 行が存在し、かつ game_center_id が空ではない場合
                hasProfile = true
            } else {
                // 行がない、または game_center_id が空の場合
                hasProfile = false
            }
            
            print("checkProfile result: \(hasProfile) (User ID: \(userId))")
            
        } catch {
            print("checkProfile error:", error)
            hasProfile = false
        }
    }
}
