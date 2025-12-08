//
//  MakerView.swift
//  terricapMap
//
//  Created by 友田采芭 on 2025/11/19.
//

import SwiftUI
import CoreLocation

struct MarkerView: View {
    
    var item: Location
    
    var body: some View {
        ZStack{
            Image(systemName: "bubble.middle.bottom.fill")
                .resizable()
                .frame(width: 80.0, height: 100)
//                .foregroundColor(item.statusColor)
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
            Rectangle()
                .frame(width: 65, height: 65)
                .foregroundColor(.white.opacity(0.8))
                .cornerRadius(10)
                .padding(.bottom, 19)
            VStack{
                Text("\(item.tasks?.first?.goal_move_value ?? 0)歩")
                Text("\(item.tasks?.first?.goal_spot_value ?? 0)kcal")
            }
            .foregroundColor(.black.opacity(0.8))
            .padding(.bottom, 19)
        }
    }
}
//
//#Preview {
//    MarkerView(item: MapItem(occupy: false))
//}
