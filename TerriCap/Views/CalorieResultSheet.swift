//
//  CalorieResultSheet.swift
//  TerriCap
//
//  Created by 濱松未波 on 2026/01/28.
//
import SwiftUI

struct CalorieResultSheet: View {
    let targetCalories: Double
    @State private var displayCalories: Double = 0.0 // 表示用の数字
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 30) {
            Text("前回のタスク達成報告")
                .font(.headline)
                .padding(.top)

            VStack(spacing: 10) {
                Text("前回のタスク達成により消費できたカロリーは")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(alignment: .bottom) {
                    // ✨ String(format:) で小数第一位まで表示
                    Text(String(format: "%.1f", displayCalories))
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        .contentTransition(.numericText()) // 数字の変化を滑らかにする

                    Text("kcal")
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 12)
                }
            }
            .padding(.vertical, 40)

            Button("閉じる") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .onAppear {
            // 1.5秒かけて目標値まで増えるアニメーション
            withAnimation(.easeOut(duration: 1.5)) {
                displayCalories = targetCalories
            }
        }
    }
}
