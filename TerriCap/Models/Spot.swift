//
//  Models.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/11/22.
//

import Foundation
import CoreLocation

struct ParkUploadData: Codable, Identifiable, Equatable {
    let name: String
    let latitude: Double
    let longitude: Double
    let place_id: String?
    var taskscores: [ParkTask]?
    
    var id: String {
        return place_id ?? name
    }
    
    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
    
    // 選択された公園を比較する
    static func == (lhs: ParkUploadData, rhs: ParkUploadData) -> Bool {
        return lhs.id == rhs.id
    }
}
