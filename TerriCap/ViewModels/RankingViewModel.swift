//
//  RankingViewModel.swift
//  TerriCap
//
//  Created by 濱松未波 on 2026/03/19.
//
import SwiftUI
import Combine
import Supabase

// ランキングに表示するユーザーのモデル
struct RankedUser: Identifiable {
    let id: UUID
    let rank: Int
    let name: String
    let score: Int 
}

@MainActor
class RankingViewModel: ObservableObject {
    @Published var monthlyRanking: [RankedUser] = []
    @Published var weeklyRanking: [RankedUser] = []
    @Published var isLoading = false

    // サンプルデータを読み込む（後でSupabaseからの取得処理に書き換えます）
    func fetchRankings() async {
        isLoading = true
        defer { isLoading = false }

        // 通信をシミュレート
        try? await Task.sleep(nanoseconds: 500_000_000)

        // 月間ランキングのモックデータ
        monthlyRanking = [
            RankedUser(id: UUID(), rank: 1, name: "PUK太郎", score: 15000),
            RankedUser(id: UUID(), rank: 2, name: "あ", score: 12000),
            RankedUser(id: UUID(), rank: 3, name: "もも太郎", score: 10500),
            RankedUser(id: UUID(), rank: 4, name: "金太郎", score: 9800),
            RankedUser(id: UUID(), rank: 5, name: "うらしまたろう", score: 8000)
        ]

        // 週間ランキングのモックデータ
        weeklyRanking = [
            RankedUser(id: UUID(), rank: 1, name: "PUK太郎", score: 4500),
            RankedUser(id: UUID(), rank: 2, name: "あ", score: 4200),
            RankedUser(id: UUID(), rank: 3, name: "もも太郎", score: 3800),
            RankedUser(id: UUID(), rank: 4, name: "金太郎", score: 3100),
            RankedUser(id: UUID(), rank: 5, name: "うらしまたろう", score: 2900)
        ]
    }
}
