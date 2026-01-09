//
//  AToZView.swift
//  TerriCap
//
//  Created by 友田采芭 on 2025/12/04.
//

import SwiftUI

struct AToZView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var nickname: String = ""
    @State private var alphabet: String = ""
    @State private var selectColor: Color = .red
    @FocusState private var isFocused: Bool
    @StateObject private var viewModel = ProfileViewModel()
    let presetColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown, .gray, .black
    ]
    let columns = Array(repeating: GridItem(), count: 7)
    
    var body: some View {
        ZStack{
            Color.white
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isFocused = false
                }
            VStack{
                Text("プロフィール作成")
                    .font(.title2)
                    .fontWeight(.bold)
                    .opacity(0.6)
                ZStack{
                    Circle()
                        .fill(selectColor)
                        .frame(width: 150, height: 150)
                    Circle()
                        .fill(.white.opacity(0.8))
                        .frame(width: 120, height: 120)
                    Text(alphabet.uppercased())
                        .foregroundStyle(selectColor)
                        .font(.system(size: 90))
                }
                .padding(.vertical, 50)
                VStack{
                    VStack(alignment: .leading){
                        Text("ニックネームを入力（15文字以内）")
                            .font(.headline)
                            .opacity(0.6)
                            .padding(.bottom, -10)
                        TextField("プク太郎", text: $nickname)
                            .focused($isFocused)
                            .font(.title2)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 340, height: 60)
                            .onChange(of: nickname) { oldValue, newValue in
                                let removeSpace = newValue.filter {!$0.isWhitespace && $0.isLetter}
                                if newValue != removeSpace {
                                    nickname = removeSpace
                                }
                                if nickname.count > 15 {
                                    nickname = String(nickname.prefix(15))
                                }
                            }
                    }
                    VStack(alignment: .leading){
                        Text("A-Zを1文字入力")
                            .font(.headline)
                            .opacity(0.6)
                            .padding(.bottom, -10)
                        TextField("A", text: $alphabet)
                            .focused($isFocused)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 340, height: 60)
                            .textInputAutocapitalization(.characters)
                            .keyboardType(.asciiCapable) // 英字キーボード
                            .onChange(of: alphabet){ _, newValue in
                                let removeSpace = newValue.filter {!$0.isWhitespace && $0.isASCII && $0.isLetter}
                                if alphabet != removeSpace {
                                    alphabet = removeSpace
                                }
                                if alphabet.count > 1 {
                                    alphabet = String(alphabet.suffix(1))
                                }
                            }
                    }
                    .padding(.vertical, 5)
                    VStack(alignment: .leading){
                        Text("背景色を選択")
                            .font(.headline)
                            .opacity(0.6)
                            .padding(.leading, 30)
                        LazyVGrid(columns: columns, spacing: 7){
                            ForEach(presetColors, id: \.self){ color in
                                Circle()
                                    .fill(color)
                                    .frame(height: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectColor == color ? 3 : 0)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.gray,lineWidth: selectColor == color ? 1 : 0)
                                            .frame(width: 50, height: 50)
                                    )
                                    .onTapGesture{
                                        withAnimation(.spring()) {
                                            selectColor = color
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 5)
                    }
                    .padding(.bottom, 40)
                    Button {
                        Task {
                            await saveProfile()
                        }
                    } label: {
                        Text(viewModel.isSaving ? "保存中…" : "決定")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 352, height: 44)
                            .background(!alphabet.isEmpty && !nickname.isEmpty ? Color.blue : Color.gray.opacity(0.5))
                            .cornerRadius(8)
                    }
                    .disabled(alphabet.isEmpty && nickname.isEmpty)
                }
            }
        }
    }
    
    private func saveProfile() async {
        let success = await viewModel.saveProfile(
            name: nickname,
            alphabet: alphabet,
            color: selectColor.description
        )
        if success {
            authManager.hasProfile = true
        }
    }
}

#Preview {
    AToZView()
}
