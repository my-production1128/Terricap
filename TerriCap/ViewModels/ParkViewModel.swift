//
//  LocationViewModel.swift
//  TerriCap
//  Created by 末廣月渚 on 2025/11/20.
//
import Foundation
import SwiftUI
import Combine
import CoreLocation

@MainActor
final class ParkViewModel: ObservableObject {
    // 画面に表示するための公園リスト
    @Published var parks: [ParkUploadData] = []
    
    // エラーメッセージ表示用
    @Published var error: String?
    
    // 通信中（ローディング）を示すフラグ
    @Published var isLoading: Bool = false
    
    // 先ほど作った Repository を読み込む
    private let repository: ParkRepository

    // 初期化時に Singleton の shared を渡すようにします
    init(repository: ParkRepository = .shared) {
        self.repository = repository
    }

    // 1. Supabaseから保存済みの公園を取得するメソッド
    func fetchParks() async {
        isLoading = true
        defer { isLoading = false } // 処理が終わったら必ずローディングを解除
        
        do {
            // Repositoryの取得メソッドを呼ぶ
            let fetchedParks = try await repository.fetchSavedParks()
            self.parks = fetchedParks
        } catch {
            self.error = error.localizedDescription
            print("DEBUG: fetchParks error: \(error)")
        }
    }

    // 2.指定した座標の周辺を検索し、保存して、リストを更新するメソッド
    func searchAndSaveParks(at coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // ① MapKitで現在地周辺の公園を検索
            let newParks = try await repository.searchParksFromMap(at: coordinate)
            
            if !newParks.isEmpty {
                // ② 見つかったらSupabaseに保存 (Upsert)
                try await repository.saveParks(newParks)
                print("DEBUG: \(newParks.count)件の公園を保存しました")
                
                // ③ 保存が終わったら、最新のリストを再取得して画面を更新
                await fetchParks()
            } else {
                print("DEBUG: 周辺に公園が見つかりませんでした")
            }
        } catch {
            self.error = error.localizedDescription
            print("DEBUG: searchAndSaveParks error: \(error)")
        }
    }
}
