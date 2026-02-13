//
//  GameCenterService.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2026/02/13.
//

import SwiftUI
import GameKit
import Observation

@Observable
final class GameCenterViewModel {
    // MARK: - Inputs (Viewからの入力)
    var authenticationViewController: UIViewController? // ログイン画面表示用
    
    // MARK: - Outputs (Viewへの出力)
    var isSaving = false
    var errorMessage: String?
    var isSuccess = false
    
    // MARK: - Dependencies
    private let profileRepository = ProfileRepository() // シングルトンがあればそれを使ってください
    
    /// 処理の開始：Game Center認証 -> 成功ならSupabase保存
    @MainActor
    func startConnectionProcess(userId: UUID, onComplete: @escaping () -> Void) {
        // 1. Game Center認証開始
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self = self else { return }
            
            // A. ログイン画面を表示する必要がある場合
            if let vc = viewController {
                self.authenticationViewController = vc
                return
            }
            
            // B. エラーが発生した場合
            if let error = error {
                self.errorMessage = "Game Center認証エラー: \(error.localizedDescription)"
                return
            }
            
            // C. 認証成功した場合
            if GKLocalPlayer.local.isAuthenticated {
                // ID取得 (iOS 12.4+ teamPlayerID, fallback gamePlayerID)
                let gcID = GKLocalPlayer.local.teamPlayerID
                print("Game Center認証成功: \(gcID)")
                
                // 2. 続けてSupabaseへ保存
                Task {
                    await self.saveToSupabase(userId: userId, gameCenterId: gcID, onComplete: onComplete)
                }
            }
        }
    }
    
    /// Supabaseへの保存処理
    @MainActor
    private func saveToSupabase(userId: UUID, gameCenterId: String, onComplete: @escaping () -> Void) {
        guard !isSaving else { return }
        self.isSaving = true
        self.errorMessage = nil
        
        Task {
            do {
                // Repository経由で保存 (Upsert)
                try await profileRepository.updateGameCenterId(userId: userId, gameCenterId: gameCenterId)
                
                // 成功
                self.isSuccess = true
                self.isSaving = false
                
                // 完了コールバック（ここでAuthManagerのリフレッシュなどを呼ぶ）
                onComplete()
                
            } catch {
                self.errorMessage = "データ保存失敗: \(error.localizedDescription)"
                self.isSaving = false
            }
        }
    }
}
