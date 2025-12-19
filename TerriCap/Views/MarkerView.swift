//
//  MakerView.swift
//  terricapMap
//
//  Created by 友田采芭 on 2025/11/19.
//

import SwiftUI
import CoreLocation

struct MarkerView: View {
    
    let item: Location
    
    var body: some View {
        ZStack{
            Circle()
                .fill(.gray)
                .frame(width: 15, height: 11)
            ZStack{
                Image(systemName: "bubble.middle.bottom.fill")
                    .resizable()
                    .frame(width: 110, height: 110)
                    .cornerRadius(16)
                //                .foregroundColor(item.statusColor)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
                ZStack{
                    Rectangle()
                        .frame(width: 95, height: 75)
                        .foregroundColor(.white.opacity(0.8))
                        .cornerRadius(13)
                    VStack{
                        HStack{
                            Image(systemName: "flag.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 15, height: 15)
                                .padding(-3)
                            Text("\(item.tasks?.first?.goal_move_value ?? 2000)歩")
                        }
                        HStack{
                            //🦪🐸かも
                            Image(systemName: "figure.strengthtraining.functional")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 15, height: 15)
                                .padding(-3)
                            Text("\(item.tasks?.first?.goal_spot_value ?? 200)kcal")
                        }
                    }
                    .foregroundColor(.black.opacity(0.8))
                }
                
            .padding(.bottom, 21)
            }
            .offset(x: 0, y: -55)
        }
    }
}
//
//#Preview {
//    MarkerView(item: Location(id: 222222, name: "熊本県立大学", latitude: 100, longitude: 100, tasks: []))
//}
