////
////  NotificationManager.swift
////  step tracker
////
////  Created by 濱松未波 on 2025/11/18.
////
//import Foundation
//import UserNotifications
//
//final class NotificationManager {
//
//    static var shared = NotificationManager()
//    private init() {
//
//    }
//
//    private var lastSendDate: Date?
//
//   // 権限リクエスト
//   func requestPermission() {
//       UNUserNotificationCenter.current()
//           .requestAuthorization(options: [.alert, .sound, .badge]) { (granted, _) in
//               print("Permission granted: \(granted)")
//           }
//   }
//
//   // notificationの登録
//    func sendNotification(title: String?, body: String?) {
//        let now = Date()
//        // 10秒以内にメソッドを呼ばれた場合はreturn
//        if let lastSendDate = lastSendDate, abs(now.timeIntervalSince(lastSendDate)) < 10 {
//            return
//        }
//        lastSendDate = now
//
//
//       let content = UNMutableNotificationContent()
//       content.title = title ?? "デフォルトタイトル"
//       content.body = body ?? "デフォルト本文"
//
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
//        let request = UNNotificationRequest(identifier: "com.pedometer.sample", content: content, trigger: trigger)
//
//       UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
//   }
//}
//
