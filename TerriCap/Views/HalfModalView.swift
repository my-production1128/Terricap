//
//  HalfModalView.swift
//  TerriCap
//
//  Created by 友田采芭 on 2025/11/24.
//

import SwiftUI

struct HalfModalView: View {
    let item: Location
    let occupy: String
    @Environment(\.dismiss) private var dismiss

//    歩数計用
    @StateObject var viewModel: StepViewModel
    @Binding var istargetLocation: Bool
//    init(viewModel: StepViewModel) {
//            self.location = location
//            self._viewModel = StateObject(wrappedValue: viewModel)
//        }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.6))
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
                    Text("\(item.name)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Button{
                        istargetLocation = true
                        viewModel.startMeasurement(target: item)
                        dismiss()
                    }label: {
                        Image(systemName: "figure.walk.circle.fill")
                            .resizable()
                            .frame(width: 50,height: 50)
                            .padding(.leading, 4)
                            .padding(.trailing, 19)
                            .foregroundStyle(Color.blue)
                    }
                }
                .padding(.top, 30)
                Text(occupy)
                    .foregroundStyle(.gray)
                    .padding(.vertical, 12)
                HStack{
                    ZStack{
                        Rectangle()
                            .fill(.orange)
                            .frame(width: 180, height: 100)
                            .cornerRadius(10)
                        VStack{
                            Text("辿り着くまでの歩数")
                                .font(.headline)
                            HStack{
                                Text("\(item.tasks?.first?.goal_move_value ?? 0)")
                                    .font(.largeTitle)
                                    .fontWeight(.heavy)
                                Text("歩")
                                    .font(.title2)
                            }
                        }
                        .foregroundStyle(.white)
                    }
                    ZStack{
                        Rectangle()
                            .fill(.green)
                            .frame(width: 180, height: 100)
                            .cornerRadius(10)
                        VStack{
                            Text("消費するカロリー")
                                .font(.headline)
                            HStack{
                                Text("\(item.tasks?.first?.goal_spot_value ?? 0)")
                                    .font(.largeTitle)
                                    .fontWeight(.heavy)
                                Text("kcal")
                                    .font(.title)
                            }
                        }
                        .foregroundStyle(.white)
                    }
                }
                .padding(.vertical, 5)
                ZStack{
                    Rectangle()
                        .fill(.red)
                        .frame(width: 370, height: 100)
                        .cornerRadius(10)
                    VStack{
                        Text("スポット占有での獲得ポイント")
                            .font(.headline)
                        HStack{
                            Text("\(item.tasks?.first?.goal_point_value ?? 0)")
                                .font(.largeTitle)
                                .fontWeight(.heavy)
                            Text("P")
                                .font(.title)
                        }
                    }
                    .foregroundStyle(.white)
                }
                Spacer()
            }
        }
        //インジケーター（View上部の「ー」）
        .presentationDragIndicator(.visible)
        .ignoresSafeArea(edges: .bottom)
    }
}
