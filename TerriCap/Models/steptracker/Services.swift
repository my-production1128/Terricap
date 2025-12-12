//
//  Services.swift
//  step tracker
//
//  Created by 濱松未波 on 2025/11/19.
//
import Foundation
import HealthKit

// PedometerManagerが持つべき機能を定義
protocol PedometerServiceType: AnyObject {
    // delegateをセットできるようにする
    var delegate: PedometerManagerDelegate? { get set }

    // 既存のメソッドを定義
    func startUpdates()
    func stopUpdates()
}

// LocationManagerが持つべき機能を定義
protocol LocationServiceType {
    // 既存のメソッドを定義
    func setup()
    func startUpdateLocation()
    func stopUpdateLocation()
}

protocol HealthKitServiceType: AnyObject {
    // 外部に歩数を通知するためのデリゲート
    var delegate: HealthKitManagerDelegate? { get set }

    // 権限リクエスト
    func requestAuthorization() async throws

    // リアルタイムの歩数計測を開始
    func startStepCountUpdates()

    // 既存の履歴歩数を取得 (課題で提供されたコードを参考に非同期メソッドとして定義)
    func fetchStepCountSum(from startDate: Date, to endDate: Date) async -> Double?
}

protocol HealthKitManagerDelegate: AnyObject {
    // リアルタイム歩数更新時に呼ばれる
    func healthKitManager(_ manager: HealthKitServiceType, didUpdateNumberOfSteps steps: Double)
}
