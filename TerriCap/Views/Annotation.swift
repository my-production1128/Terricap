//
//  MakerView.swift
//  terricapMap
//
//  Created by 友田采芭 on 2025/11/19.
//

import SwiftUI
import CoreLocation

struct MakerView: View {
    
    var item: MapItem
    
    var body: some View {
        Image(systemName: "bubble.middle.bottom.fill")
            .resizable()
            .frame(width: 80.0, height: 100)
            .foregroundColor(item.color)
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
    }
}
