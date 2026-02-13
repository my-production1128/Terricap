//
//  GameCenterConnectView.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2026/02/13.
//

import SwiftUI

struct GameCenterConnectView: View {
    // ロジックを持つViewModelを所有
    @State private var viewModel = GameCenterViewModel()
    
    // アプリ全体のユーザー状態（リフレッシュ用）
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            Text("Game Centerと連携")
                .font(.title2.bold())
            
            // 状態に応じたUIの切り替え
            if viewModel.isSaving {
                ProgressView("設定を保存中...")
            } else if viewModel.isSuccess {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.green)
                Text("連携完了！")
            } else {
                descriptionView
                
                // 連携ボタン
                Button {
                    guard let userId = authManager.currentUserId else { return }
                    
                    // ViewModelに処理を依頼
                    viewModel.startConnectionProcess(userId: userId) {
                        // 完了後の処理 (AuthManagerの更新など)
                        Task {
                            await authManager.refreshUser()
                        }
                    }
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
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        // Game Centerログイン画面（シート）の制御
        .sheet(item: Binding(
            get: { viewModel.authenticationViewController.map { IdentifiableViewController(vc: $0) } },
            set: { if $0 == nil { viewModel.authenticationViewController = nil } }
        )) { wrapper in
            GameCenterLoginSheet(viewController: wrapper.vc)
        }
    }
    
    // 説明文のView（切り出し）
    private var descriptionView: some View {
        Text("歩数バトルに参加するために\nGame Centerアカウントを使用します。")
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
    }
}
