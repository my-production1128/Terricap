//
//  HalfModalView.swift
//  TerriCap
//
//  Created by 友田采芭 on 2025/11/24.
//

import SwiftUI

struct HalfModalView: View {
    let location: MapItem
    @Environment(\.dismiss) private var dismiss

//    歩数計用
    @StateObject private var viewModel: StepViewModel
    init(location: MapItem, viewModel: StepViewModel) {
            self.location = location
            self._viewModel = StateObject(wrappedValue: viewModel)
        }

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.white.opacity(0.6))
            VStack {
                HStack{
                    Button{
                        dismiss()
                    }label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 50,height: 50)
                            .padding(.leading, 19)
                            .padding(.trailing, 4)
                            .foregroundStyle(Color.gray)
                    }
                    Spacer()
                    Text("\(location.name)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Button{
                        viewModel.startMeasurement()
                    }label: {
                            Image(systemName: "arrowtriangle.right.circle.fill")
                                .resizable()
                                .frame(width: 50,height: 50)
                                .padding(.leading, 4)
                                .padding(.trailing, 19)
                    }
                }
                .padding(.top, 30)
                VStack{
                    if location.occupy == true {
                        Text("今このスポットはあなたが占有しています")
                    }else if location.occupy == false {
                        Text("今このスポットは他の人が占有しています")
                    }else{
                        Text("今このスポットは誰のものでもありません")
                    }
                }
                .foregroundColor(.gray)
                .padding(.vertical, 12)
                HStack{
                    ZStack{
                        Rectangle()
                            .frame(width: 180, height: 100)
                            .foregroundColor(.orange)
                            .cornerRadius(8)
                        VStack{
                            Text("辿り着くまでの歩数")
                                .font(.headline)
                            HStack{
                                Text("2000")
                                    .font(.largeTitle)
                                    .fontWeight(.heavy)
                                Text("歩")
                                    .font(.title2)
                            }
                        }
                        .foregroundColor(.white)
                    }
                    ZStack{
                        Rectangle()
                            .frame(width: 180, height: 100)
                            .foregroundColor(.green)
                            .cornerRadius(8)
                        VStack{
                            Text("消費するカロリー")
                                .font(.headline)
                            HStack{
                                Text("50")
                                    .font(.largeTitle)
                                    .fontWeight(.heavy)
                                Text("kcal")
                                    .font(.title)
                            }
                        }
                        .foregroundColor(.white)
                    }
                }
                .padding(.vertical, 5)
                ZStack{
                    Rectangle()
                        .frame(width: 370, height: 100)
                        .foregroundColor(.brown)
                        .cornerRadius(8)
                    VStack{
                        Text("スポット確保での獲得ポイント")
                            .font(.headline)
                        HStack{
                            Text("1000")
                                .font(.largeTitle)
                                .fontWeight(.heavy)
                            Text("P")
                                .font(.title)
                        }
                    }
                    .foregroundColor(.white)
                }
                Spacer()
            }
        }
        //インジケーター（View上部の「ー」）
        .presentationDragIndicator(.visible)
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    HalfModalView(location: MapItem(name: "熊本県立大学"))
}
