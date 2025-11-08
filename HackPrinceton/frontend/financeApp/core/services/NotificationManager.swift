//
//  NotificationManager.swift
//
//
//  Created by Annabella Rinaldi on 11/8/25.
//
import Foundation
import UserNotifications
import CoreLocation

final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // MARK: - Permission Handling
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Trigger Notifications (Backend calls these)
    
    /// Sends immediate notification when user enters trigger location
    func sendLocationAlert(
        locationName: String,
        averageSpend: Decimal,
        riskLevel: RiskLevel,
        distance: Double
    ) {
        let content = UNMutableNotificationContent()
        
        // Match the aggressive tone of Uber Eats/FanDuel but reversed
        switch riskLevel {
        case .high:
            content.title = "🚨 DANGER ZONE"
            content.body = "You're at \(locationName) - you blow $\(averageSpend) here every time"
        case .medium:
            content.title = "⚠️ Watch out"
            content.body = "\(locationName) nearby - avg damage: $\(averageSpend)"
        case .low:
            content.title = "👀 Heads up"
            content.body = "\(locationName) ahead - you spend $\(averageSpend) here"
        }
        
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "LOCATION_ALERT"
        
        // Trigger after 5 seconds to give time to press Home
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
    
    /// Sends time-based vulnerability alert
    func sendTimeBasedAlert(message: String, riskLevel: RiskLevel) {
        let content = UNMutableNotificationContent()
        
        content.title = "⏰ Late night spending alert"
        content.body = message
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Sends emotional/stress-based alert
    func sendEmotionalAlert(message: String) {
        let content = UNMutableNotificationContent()
        
        content.title = "🧠 Stress spending incoming"
        content.body = message
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Sends social spending alert
    func sendSocialAlert(message: String) {
        let content = UNMutableNotificationContent()
        
        content.title = "👥 Your friends are spending"
        content.body = message
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Sends success/reinforcement notification
    func sendSuccessNotification(message: String) {
        let content = UNMutableNotificationContent()
        
        content.title = "🎉 You're killing it!"
        content.body = message
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Badge Management
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
