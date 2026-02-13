//
//  ProfileViewModel.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/12/11.
//
//
//  ProfileViewModel.swift
//  TerriCap
//
import Combine
import Foundation
import SwiftUI
import Supabase

@MainActor
final class ProfileViewModel: ObservableObject {
    
    // MARK: - Published (画面に反映されるデータ)
    @Published var profile: Profile?
    @Published var isSaving = false        // ボタンのグルグル用
    @Published var isLoading = false       // 初回読み込み用
    @Published var errorMessage: String?   // エラー表示用
    @Published var showSuccessAlert = false // 成功アラート用
    
    // MARK: - Dependencies (機能パーツ)
    private let repository: ProfileRepository

    init(repository: ProfileRepository? = nil) {
        if let repository {
            self.repository = repository
        } else {
            self.repository = ProfileRepository()
        }
    }
    
    // MARK: - Functions
    
    /// プロフィール情報を取得する
    func fetchProfile() async {
        isLoading = true
        defer { isLoading = false } // 処理が終わったら必ずfalseにする
        
        do {
            // ログイン中のユーザーIDを取得
            guard let user = SupabaseManager.shared.client.auth.currentUser else {
                return
            }
            
            // リポジトリからデータ取得
            let fetchedProfile = try await repository.fetchProfile(userId: user.id)
            self.profile = fetchedProfile
            
        } catch {
            print("Fetch Error: \(error)")
        }
    }
    
    /// Game Centerと連携する（ボタンから呼ばれる）
    func linkGameCenter() async {
        // 1. Supabaseログインチェック
        guard let user = SupabaseManager.shared.client.auth.currentUser else {
            self.errorMessage = "Supabaseにログインしていません"
            return
        }
        
        isSaving = true
        errorMessage = nil // エラーリセット
        
        do {
            // 2. Game Centerの認証 & ID取得
            // (シミュレーターだとここでエラーになることが多いので実機推奨)
            // TODO: Inject a GameCenterService dependency and call it here to fetch the player ID.
            // let gcId = try await gameCenterService.authenticateAndFetchPlayerID()
            // Temporary placeholder to keep build green until GameCenterService is provided:
            struct MissingGameCenterServiceError: Error {}
            throw MissingGameCenterServiceError()
            
            // print("Game Center ID取得成功: \(gcId)")
            
            // 3. SupabaseにIDを保存
            // try await repository.updateGameCenterId(userId: user.id, gameCenterId: gcId)
            
            // 4. 成功したらプロフィールを再取得して画面を更新
            // await fetchProfile()
            
            // 成功アラートを出す
            // self.showSuccessAlert = true
            // print("連携成功！")
            
        } catch {
            self.errorMessage = "連携に失敗しました: \(error.localizedDescription) (GameCenterService not wired)"
            print("Link Error: \(error)")
        }
        
        isSaving = false
    }
}

