//
//  AvatarRandomView.swift
//  TerriCap
//
//  Created by 友田采芭 on 2026/02/22.
//

import SwiftUI
import Charts
import RealityKit

struct SlimeView: View {
    @StateObject private var viewModel = ProfileViewModel()
    
    @AppStorage("total_steps_all_time") var totalSteps: Double = 0
    @AppStorage("total_calories_all_time") var totalCalories: Double = 0.0
    //ドーナツ一周分
    let stepFeed: Double = 50000
    let calFeed: Double = 2500.0
    
    //仮データ
//    @State var totalSteps2: Double = 40000
//    @State var totalCalories2: Double = 300.0
    
    //--計算型プロパティ--
    //歩数
    var stepGoal: Int { Int(totalSteps / stepFeed) }
    var steps: Double { totalSteps.truncatingRemainder(dividingBy: stepFeed) }
    
    //カロリー
    var calGoal: Int { Int(totalCalories / calFeed) }
    var calories: Double { totalCalories.truncatingRemainder(dividingBy: calFeed) }
    
    //達成回数
    var achievement: Int { stepGoal + calGoal }
    
    var body: some View {
        VStack {
            Text(sizeLabel(achievement))
                .font(.title.bold())
                .padding()
                //最初に1回だけ動く
                RealityView { content in
                    if let model = try? await Entity(named: "SlimeFrontFace"){
                        print("モデル読み込み成功")
                        
                        model.name = "slime"
                        
                        // メートル
                        model.scale = [0.7, 0.7, 0.7]
                        model.position = [0, -0.3, 0]
                        model.orientation = simd_quatf(angle: .pi / 40, axis: [1.2, 3.5, 0])
                        
                        content.add(model) //画面に追加
                    } else {
                        print("モデル読み込み失敗")
                    }
                    
                    let sunLight = DirectionalLight()
                    // ライトの強さ
                    sunLight.light.intensity = 5000
                    // look(at: ターゲットの場所, from: ライトを置く場所, relativeTo: 基準)
                    sunLight.look(at: [0, -0.3, 0], from: [3, 5, 2], relativeTo: nil)
                    content.add(sunLight)
                    
                } update: { content in
                    //"slime"モデル探す
                    if let character = content.entities.first(where: { $0.name == "slime" }) {
                        // 形あり(ModelEntity)だけをリスト化
                        let allParts = findAllModelEntities(in: character)
                        
                        // 順番に色を塗る
                        if allParts.count >= 3 {
                            
                            if let userData = viewModel.profile {
                                
                                var skinColor: UIColor {
                                    UIColor(hue: CGFloat(userData.first_value) * 0.85, saturation: 0.6, brightness: 1.0, alpha: 1.0)
                                }
                                var patternColor: UIColor {
                                    UIColor(hue: CGFloat(userData.second_value), saturation: 0.2 + CGFloat(userData.first_value) * 0.8, brightness: 1.0, alpha: 1.0)
                                }
                                // --- 体 ---
                                let bodyPart = allParts[0]
                                if var mat = bodyPart.model?.materials.first as? PhysicallyBasedMaterial {
                                    mat.baseColor = .init(tint: skinColor, texture: nil)
                                    bodyPart.model?.materials = [mat]
                                }
                                
                                // --- 模様 ---
                                let patternPart = allParts[2]
                                if var mat = patternPart.model?.materials.first as? PhysicallyBasedMaterial {
                                    let currentTexture = mat.baseColor.texture
                                    mat.baseColor = .init(tint: patternColor, texture: currentTexture)
                                    mat.blending = .transparent(opacity: 1.0)
                                    patternPart.model?.materials = [mat]
                                }
                            }
                        }
                    }
                }
                .frame(height: 350)
//                .padding(.top, 50)
//            }
//            .padding(.bottom, 70)
            
            Gauge(
                value: currentProgress(for: achievement),
                in: 0...levelMaxTarget(for: achievement),
                label: {
                    Text("レベルアップ")
                },
                currentValueLabel: {
                    Text("\(Int(currentProgress(for: achievement)))")
                },
                minimumValueLabel: {
                    Text("0")
                },
                maximumValueLabel: {
                    Text("\(Int(levelMaxTarget(for: achievement)))")
                }
            )
            .tint(Color(.green))
            .padding()
            
            //歩数での達成度グラフ
            Gauge(value: steps, in: 0...stepFeed) {
                Text("歩数")
            } currentValueLabel: {
                Text("\(Int(steps))")
            }  minimumValueLabel: {
                Text("  0 ")
                    .font(Font.system(size: 13))
            }maximumValueLabel: {
                Text("\(Int(stepFeed))")
                    .font(Font.system(size: 13))
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .padding(.horizontal)
            
            //カロリーでの達成度グラフ
            Gauge(value: calories, in: 0...calFeed) {
                Text("カロリー（kcal）")
            } currentValueLabel: {
                Text(String(format: "%.1f", calories))
            }  minimumValueLabel: {
                Text("0.0")
                    .font(Font.system(size: 13))
            }maximumValueLabel: {
                Text(String(format: "%.1f", calFeed))
                    .font(Font.system(size: 13))
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .tint(.orange)
            .padding()
//            Spacer()
            HStack{
                Text(String(format: "%.f 歩　",totalSteps))
                    .foregroundStyle(Color.blue)
                Text(String(format: "%.1f kcal", totalCalories))
                    .foregroundStyle(Color.orange)
            }
        }
        .task {
            await viewModel.fetchProfile()
        }
    }
    private func sizeLabel(_ level: Int) -> String {
        switch level {
        case 35...: return "地球レベル"
        case 27...: return "エベレストレベル"
        case 20...: return "富士山レベル"
        case 14...: return "スカイツリーレベル"
        case 9...: return "観覧車レベル"
        case 5...:  return "自転車レベル"
        case 2...:  return "サッカーボールレベル"
        default:    return "お茶碗レベル"
        }
    }
    private func currentProgress(for total: Int) -> Double {
        switch total {
        case ..<2:  return Double(total - 0)
        case ..<5:  return Double(total - 2)
        case ..<9:  return Double(total - 5)
        case ..<14: return Double(total - 9)
        case ..<20: return Double(total - 14)
        case ..<27: return Double(total - 20)
        case ..<35: return Double(total - 27)
        default:    return 1.0
        }
    }
    
    // ゲージの最大値
    private func levelMaxTarget(for total: Int) -> Double {
        switch total {
        case ..<2:  return 2.0
        case ..<5:  return 3.0
        case ..<9:  return 4.0
        case ..<14: return 5.0
        case ..<20: return 6.0
        case ..<27: return 7.0
        case ..<35: return 8.0
        default:    return 1.0
        }
    }
    private func findAllModelEntities(in entity: Entity) -> [ModelEntity] {
        var parts: [ModelEntity] = []
        
        // 自分がModelEntityならリストに入れる
        if let modelEntity = entity as? ModelEntity {
            parts.append(modelEntity)
        }
        
        // 子供たちも全部チェックしてリストに追加する
        for child in entity.children {
            parts.append(contentsOf: findAllModelEntities(in: child))
        }
        
        return parts // リストを返す
    }
}

#Preview {
    SlimeView()
}
