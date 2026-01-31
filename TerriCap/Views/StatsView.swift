//
//  StatsView.swift
//  TerriCap
//
//  Created by 濱松未波 on 2026/01/27.
//
import SwiftUI

struct StatsView: View {
    // UserDefaultsの値をリアルタイム監視（サーバー通信なし）
    @AppStorage("total_steps_all_time") var totalSteps: Int = 0
    @AppStorage("total_calories_all_time") var totalCalories: Double = 0.0

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("累計歩数 (タスク中)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(totalSteps) 歩")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("累計消費カロリー (Apple Watch)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f kcal", totalCalories))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("これまでの積み上げ")
                }

                Section {
                    Text("※歩数はアプリ内の計測分のみ集計されます。")
                    Text("※消費カロリーは、データ同期の都合上、タスク終了から12時間後以降に順次反映されます。")
                } footer: {
                    Text("Apple Watchのデータを元にしています。")
                }
                .font(.caption)
                .foregroundStyle(.gray)
            }
            .navigationTitle("実績")
        }
    }
}
