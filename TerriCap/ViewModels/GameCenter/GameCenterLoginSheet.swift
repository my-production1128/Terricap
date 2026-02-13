//
//  GameCenterLoginSheet.swift
//  TerriCap
//
//  Created by 末廣月渚 on 2026/02/13.
//


import SwiftUI
import UIKit

struct GameCenterLoginSheet: UIViewControllerRepresentable {
    let viewController: UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 更新不要
    }
}

struct IdentifiableViewController: Identifiable {
    let id = UUID()
    let vc: UIViewController
}
