//
//  GameCenterConnectView.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2026/02/13.
//

import SwiftUI

struct GameCenterConnectView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    // アプリ全体のユーザー状態
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            Text("Game Centerと連携")
                .font(.title2.bold())
            
            // 状態に応じたUIの切り替え
            if profileViewModel.isSaving {
                ProgressView("設定を保存中...")
            } else if profileViewModel.profile?.game_center_id != nil {
                // 連携済みの表示
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    Text("連携完了！")
                        .font(.headline)
                    
                    Text("あなたのデータは保護されています")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                descriptionView
                
                // 連携ボタン
                Button {
                    // ViewModelに連携開始を依頼
                    profileViewModel.startGameCenterConnection()
                } label: {
                    Text("連携する")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            // エラー表示
            if let error = profileViewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        // 修正：ViewModelの IdentifiableViewController を直接監視するだけ！
        .sheet(item: $profileViewModel.authViewController) { wrapper in
            GameCenterLoginSheet(viewController: wrapper.vc)
        }
    }
    
    private var descriptionView: some View {
        Text("歩数バトルに参加するために\nGame Centerアカウントを使用します。")
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
    }
}
