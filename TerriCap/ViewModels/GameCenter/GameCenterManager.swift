//
//  GameCenterManager.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2026/02/13.
//

import GameKit
import SwiftUI

/// GameCenterの「機能」だけを提供するクラス
final class GameCenterManager {
    static let shared = GameCenterManager()

    // 認証済みのプレイヤー情報を取得
    var localPlayer: GKLocalPlayer { GKLocalPlayer.local }

    // 画像を非同期で取得する（async/await対応）
    func fetchAvatar() async throws -> UIImage? {
        guard localPlayer.isAuthenticated else { return nil }
        
        return try await withCheckedThrowingContinuation { continuation in
            localPlayer.loadPhoto(for: .normal) { image, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: image)
                }
            }
        }
    }
}
