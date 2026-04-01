//
//  ParkDetailCard.swift
//  TerriCap
//
//  Created by 濱松未波 on 2026/04/01.
//
import SwiftUI

struct ParkDetailCard: View {
    let park: ParkUploadData
    let occupy: String
    let onClose: () -> Void
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // 1段目: ヘッダー（閉じるボタン・タイトル・開始ボタン）
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundStyle(Color.gray.opacity(0.8))
                }

                Spacer()

                Text(park.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(1)

                Spacer()

                Button(action: onStart) {
                    Image(systemName: "figure.walk.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundStyle(Color.blue)
                }
            }

            // 2段目: 占有状況
            Text(occupy)
                .font(.subheadline)
                .foregroundStyle(.gray)

            // 3段目: 歩数とポイント（左右に並べる）
            HStack(spacing: 12) {
                // 歩数ブロック
                VStack(spacing: 4) {
                    Text("辿り着くまでの歩数")
                        .font(.caption)
                        .fontWeight(.bold)
                    HStack(alignment: .bottom, spacing: 2) {
                        Text("\(park.taskscores?.first?.wlk ?? 2000)")
                            .font(.title2)
                            .fontWeight(.heavy)
                        Text("歩")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.orange)
                .foregroundStyle(.white)
                .cornerRadius(12)

                // ポイントブロック
                VStack(spacing: 4) {
                    Text("獲得ポイント")
                        .font(.caption)
                        .fontWeight(.bold)
                    HStack(alignment: .bottom, spacing: 2) {
                        Text("\(park.taskscores?.first?.point_value ?? 2000)")
                            .font(.title2)
                            .fontWeight(.heavy)
                        Text("P")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        // カードの影をつけて浮いているように見せる
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)
        .padding(.horizontal, 16) // 画面の端から少し離す
    }
}
