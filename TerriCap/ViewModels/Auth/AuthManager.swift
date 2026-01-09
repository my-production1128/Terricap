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
    
    // MARK: - Sign Up
    func signUp(email: String, password: String) async {
        do {
            try await authService.signUp(email: email, password: password)
            // サインアップ直後は未ログイン扱いでもOK
            self.currentUser = nil
        } catch {
            print("signUp error:", error)
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        do {
            self.currentUser = try await authService.signIn(
                email: email,
                password: password
            )
            print("signed in:", currentUser?.id ?? "nil")
        } catch {
            print("signIn error:", error)
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

        struct Row: Decodable {
            let id: UUID
        }

        do {
            let rows: [Row] = try await SupabaseManager.shared.client
                .from("profiles")
                .select("id")
                .eq("id", value: userId)
                .limit(1)
                .execute()
                .value

            hasProfile = !rows.isEmpty
            print("hasProfile:", hasProfile)
        } catch {
            print("checkProfile error:", error)
            hasProfile = false
        }
    }
}
