//
//  AToZView.swift
//  TerriCap
//
//  Created by 友田采芭 on 2025/12/04.
//

import SwiftUI
import Combine

struct AToZView: View {
    
    @State private var nickname: String = ""
    @State private var alphabet: String = ""
    @State private var selectColor: Color = .red
    @FocusState private var isFocused: Bool
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
                    .font(.title)
                ZStack{
                    Circle()
                        .frame(width: 150, height: 150)
                        .foregroundColor(selectColor)
                    Circle()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.white.opacity(0.8))
                    Text(alphabet.uppercased())
                        .font(.system(size: 90))
                        .foregroundColor(selectColor)
                }
                .padding(.vertical, 50)
                VStack{
                    VStack{
                        Text("ニックネームを入力")
                            .font(.title2)
                        TextField("ニックネーム", text: $nickname)
                            .focused($isFocused)
                            .font(.title2)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 340, height: 60)
                    }
                    HStack{
                        Text("A-Zを1文字入力：")
                            .font(.title2)
                        TextField("A", text: $alphabet)
                            .focused($isFocused)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80, height: 60)
                            .textInputAutocapitalization(.characters)
                            .keyboardType(.asciiCapable) // 英字キーボード
                            .onReceive(Just(alphabet)){ _ in
                                let removeSpace = alphabet.filter {!$0.isWhitespace && $0.isASCII && $0.isLetter}
                                if alphabet != removeSpace {
                                    alphabet = removeSpace
                                }
                                if alphabet.count > 1 {
                                    alphabet = String(alphabet.suffix(1))
                                }
                            }
                    }
                    .padding(.bottom, 20)
                    VStack{
                        Text("背景色を選択")
                            .font(.title2)
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
                    Button{
                        //🦪🐸
                        print("ボタンが押されました！")
                    }label: {
                        Text("決定")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 352, height: 44)
                            .background(!alphabet.isEmpty ? Color.blue : Color.gray.opacity(0.5))
                            .cornerRadius(8)
                    }
                    .disabled(alphabet.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AToZView()
}
