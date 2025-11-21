//
//  Models.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2025/11/22.
//

import Foundation

struct Location: Decodable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
}
