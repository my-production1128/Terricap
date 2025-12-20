//
//  ProfileViewModel.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/12/11.
//
import Combine
import Foundation
import SwiftUI
import Supabase

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: Profile_Decodable?
    @Published var isSaving = false // 保存中にローディング表示を出したい時に使うフラグ
    @Published var error: String? // エラーメッセージを View に公開するための変数

    private let repository: ProfileRepository

    init(repository: ProfileRepository = ProfileRepository()) {
        self.repository = repository
    }
    
    func fetchProfile() async {
        do {
            guard let session = try? await SupabaseManager.shared.client.auth.session else {
                self.error = "ログイン情報がありません"
                return
            }
            let user = session.user
            self.profile = try await repository.fetchProfile(userId: user.id)
            print("profile:", self.profile as Any)
            } catch {
                self.error = error.localizedDescription
            }
        }
    
    
    // AToZ から呼ばれる保存関数
    func saveProfile(name: String, alphabet: String, color: String) async -> Bool {
        // ユーザー情報取得、もし失敗したらelseでreturn false
        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            self.error = "ログイン情報がありません"
            return false
        }
        let user = session.user
        
        // AToZで決めた情報をひとまとめにした保存用のProfileデータ
        let profile = Profile_Codable(
            id: user.id,
            name: name,
            color: color,
            alphabet: alphabet
        )

        // 保存処理
        do {
            isSaving = true
            defer { isSaving = false }
            try await repository.upsertProfile(profile)
            return true
        } catch {
            self.error = error.localizedDescription
            print("Profile save error:", error)
            return false
        }
    }
}

