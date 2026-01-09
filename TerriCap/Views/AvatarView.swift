//
//  AvatarView.swift
//  TerriCap
//
//  Created by 友田采芭 on 2025/12/26.
//

import SwiftUI

struct AvatarView: View {
    @State private var selectAvatar: String = ""
    @State private var scrollPosition: String?
    let characters = ["1", "2", "3", "4", "5"]
    let gradient = Gradient(stops: [.init(color: Color.gray, location: 0.25), .init(color: Color.gray.opacity(0.2), location: 0.35), .init(color: Color.gray, location: 0.7)])
    var body: some View {
        VStack{
            Text("キャラクター選択")
                .font(.title2)
                .fontWeight(.bold)
                .opacity(0.6)
                .padding(.top, 60)
            Spacer()
            ScrollView(.horizontal) {
                HStack(spacing: 0){
                    ForEach(characters, id: \.self){ character in
                        Rectangle()
//                            .fill(Color.gray.opacity(0.1))
                            .fill(LinearGradient(
                                gradient: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 250, height: 250)
                            .overlay(){
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 220, height: 220)
                                Text(character)
                            }
                            .id(character)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrollPosition)
            .padding(20)
            HStack{
                ForEach(characters, id: \.self) { character in
                    Circle()
                        .fill(scrollPosition == character ? Color.black : Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(scrollPosition == character ? 1.2 : 1.0)
                        .animation(.default, value: scrollPosition)
                        .onAppear {
                            scrollPosition = characters.first
                        }
                }
            }
            .padding(.bottom, 20)
            Spacer()
            Button {
                Task {
                    
                }
            } label: {
                Text("決定")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 352, height: 44)
                    .background(Color.blue)
                    .cornerRadius(8)
                    .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    AvatarView()
}
