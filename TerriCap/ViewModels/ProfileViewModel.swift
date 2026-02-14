//
//  ProfileViewModel.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/12/11.
//
//
import Combine
import Foundation
import SwiftUI
import Supabase
import GameKit

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: Profile?
    @Published var avatarImage: UIImage?
    @Published var isSaving = false
    @Published var errorMessage: String?
    
    // Appleのログイン画面を出すための変数
    @Published var authViewController: IdentifiableViewController?

    private let repository = ProfileRepository()

    // 1. プロフィールと画像を最新にする（MapのonAppearなどで呼ぶ）
    func refreshAll() async {
        await fetchProfile()
        await refreshAvatar()
    }

    // 2. 画像だけを最新にする（アプリに戻ってきた時などに呼ぶ）
    func refreshAvatar() async {
        do {
            if let image = try await GameCenterManager.shared.fetchAvatar() {
                self.avatarImage = image
            }
        } catch {
            print("dbg: アイコン取得失敗: \(error)")
        }
    }

    // 3. Game Center連携を開始する
    func startGameCenterConnection() {
        GameCenterManager.shared.localPlayer.authenticateHandler = { [weak self] vc, error in
            Task { @MainActor in
                if let vc = vc {
                    // ログイン画面が必要なら表示用変数に入れる
                    self?.authViewController = IdentifiableViewController(vc: vc)
                } else if GameCenterManager.shared.localPlayer.isAuthenticated {
                    // 認証成功したら、Supabaseへ保存して画像も更新
                    await self?.saveGameCenterID()
                    await self?.refreshAvatar()
                } else if let error = error {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // 4. SupabaseにIDを保存
    private func saveGameCenterID() async {
        guard !isSaving else {
            print("保存処理中なのでスキップしました")
            return
        }
        
        if let currentProfile = profile, currentProfile.game_center_id != nil {
            print("既に連携済みのため、supabaseへの保存をスキップしました")
            return
        }
        
        guard let user = SupabaseManager.shared.client.auth.currentUser else { return }
        let gcID = GameCenterManager.shared.localPlayer.teamPlayerID
        let gcName = GameCenterManager.shared.localPlayer.alias
        isSaving = true
        
        do {
            try await repository.updateGameCenterId(userId: user.id, gameCenterId: gcID, name: gcName)
            
            await fetchProfile() // DB情報を最新に
        } catch {
            self.errorMessage = "保存失敗: \(error.localizedDescription)"
        }
        isSaving = false
    }

    func fetchProfile() async {
        guard let user = SupabaseManager.shared.client.auth.currentUser else { return }
        self.profile = try? await repository.fetchProfile(userId: user.id)
        
        if let p = self.profile {
            print("\n============  データ取得成功  ============")
            print(" 名前　　: \(p.name ?? "未設定")")
            print(" 最初の値　: \(p.first_value)")    // 0.00〜1.00
            print(" 回復率　: \(p.second_value)") // 0.00〜1.00
            print("==========================================\n")
        } else {
            print("プロフィールが見つかりませんでした（まだ作成されていない可能性があります）")
        }
    }
}

