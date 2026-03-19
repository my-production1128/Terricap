//
//  RankingView.swift
//  TerriCap
//
//  Created by 濱松未波 on 2026/03/19.
//
import SwiftUI

struct RankingView: View {
    @StateObject private var viewModel = RankingViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("読み込み中...")
                } else {
                    List {
                        // 月間ランキングセクション
                        Section {
                            ForEach(viewModel.monthlyRanking) { user in
                                RankingRow(user: user)
                            }
                        } header: {
                            Text("月間ランキング")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        // 週間ランキングセクション
                        Section {
                            ForEach(viewModel.weeklyRanking) { user in
                                RankingRow(user: user)
                            }
                        } header: {
                            Text("週間ランキング")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }
                    .listStyle(.plain) // PDFのようにシンプルなリストにする
                }
            }
            .navigationTitle("ランキング")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await viewModel.fetchRankings()
                }
            }
        }
    }
}

// 1行分のViewを切り出し
struct RankingRow: View {
    let user: RankedUser

    var body: some View {
        HStack(spacing: 16) {
            // 順位
            Text("\(user.rank)")
                .font(.title3)
                .fontWeight(.bold)
                .frame(width: 30, alignment: .leading)
                .foregroundColor(rankColor(for: user.rank))

            // アイコン（仮でグレーの丸）
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(user.name.prefix(1))) // 名前の頭文字
                        .font(.caption)
                        .foregroundColor(.black)
                )

            // 名前
            Text(user.name)
                .font(.body)

            Spacer()

            // スコア（必要であれば表示）
            Text("\(user.score) P")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    // 順位によって色を変える演出（1位は金、2位は銀など）
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .primary
        }
    }
}
