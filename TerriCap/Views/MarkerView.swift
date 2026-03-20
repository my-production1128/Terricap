//
//  MakerView.swift
//  terricapMap
//
//  Created by 友田采芭 on 2025/11/19.
//

import SwiftUI
import CoreLocation

struct MarkerView: View {
    
    let park: ParkUploadData
    let statusColor: Color
    
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
                    .foregroundColor(statusColor)
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
                           Text("\(park.taskscores?.first?.wlk ?? 2000)")
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
