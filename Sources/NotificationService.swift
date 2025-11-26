import Foundation
import UserNotifications

/// Service for managing notifications about usage thresholds
class NotificationService: ObservableObject {
    private let center = UNUserNotificationCenter.current()
    
    @Published var isAuthorized = false
    @Published var hasRequestedPermission = false
    
    init() {
        checkAuthorizationStatus()
    }
    
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                self?.hasRequestedPermission = true
                
                if granted {
                    self?.scheduleUsageNotifications()
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
                self?.hasRequestedPermission = settings.authorizationStatus != .notDetermined
            }
        }
    }
    
    func scheduleUsageNotifications() {
        // Schedule daily usage notifications
        scheduleDailyUsageNotification()
        scheduleLimitWarningNotifications()
    }
    
    private func scheduleDailyUsageNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Warp AI Usage Summary"
        content.body = "Check your daily AI usage in WarpStatus"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = AppConfiguration.uiConstants.notificationQuietHour // 8 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-usage",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    private func scheduleLimitWarningNotifications() {
        // Schedule weekly limit check (Tuesday mornings)
        let content = UNMutableNotificationContent()
        content.title = "Warp AI Usage Check"
        content.body = "You're approaching your usage limit. Check WarpStatus for details."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 3 // Tuesday
        dateComponents.hour = 9 // 9 AM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly-limit-check",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    func sendUsageAlert(usageData: WarpUsageData) {
        guard AppConfiguration.notificationThresholds.enableNotifications else { return }
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        
        switch usageData.usageStatus {
        case .warning:
            content.title = "⚠️ Warp AI Usage Warning"
            content.body = "You've used \(Int(usageData.usagePercentage * 100))% of your monthly AI tokens."
            // Use default sound for now - custom sound would need to be bundled with the app
            content.sound = UNNotificationSound.default
            
        case .critical:
            content.title = "🚨 Warp AI Usage Critical"
            content.body = "You've used \(Int(usageData.usagePercentage * 100))% of your monthly AI tokens. Consider upgrading your plan."
            content.sound = UNNotificationSound.defaultCritical
            
        case .healthy, .unlimited:
            return // No notification needed
        }
        
        let request = UNNotificationRequest(
            identifier: "usage-alert-\(UUID().uuidString)",
            content: content,
            trigger: nil // Send immediately
        )
        
        center.add(request)
    }
    
    func cancelAllNotifications() {
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }
}