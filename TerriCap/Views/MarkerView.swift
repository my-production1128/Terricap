//
//  MakerView.swift
//  terricapMap
//
//  Created by 友田采芭 on 2025/11/19.
//

import SwiftUI
import CoreLocation

struct MarkerView: View {
    
    var item: MapItem
    var statusColor: Color {
        switch item.occupy {
        case true:
            return .blue
        case false:
            return .red
        case nil:
            return .gray
        }
    }
    
    var body: some View {
        ZStack{
            Image(systemName: "bubble.middle.bottom.fill")
                .resizable()
                .frame(width: 80.0, height: 100)
                .foregroundColor(statusColor)
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
            Image(systemName: "square.fill")
                .resizable()
                .frame(width: 65, height: 65)
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 19)
            VStack{
                Text("2000歩")
                Text("50kcal")
            }
            .foregroundColor(.black.opacity(0.8))
            .padding(.bottom, 19)
        }
    }
}

#Preview {
    MarkerView(item: MapItem(occupy: false))
}
