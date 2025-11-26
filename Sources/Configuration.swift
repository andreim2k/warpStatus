import Foundation

/// Centralized configuration for the WarpStatus application
struct AppConfiguration {
    // MARK: - Refresh Settings
    static let refreshInterval: TimeInterval = 1.0
    static let retryAttempts = 3
    static let retryDelay: TimeInterval = 1.0
    
    // MARK: - File System
    static let supportedPlistNames = [
        "dev.warp.Warp-Stable.plist",
        "dev.warp.Warp-Beta.plist", 
        "dev.warp.Warp-Nightly.plist",
        "dev.warp.Warp.plist"
    ]
    
    static let preferencesDirectory = "\(NSHomeDirectory())/Library/Preferences/"
    
    // MARK: - UI Settings
    static let menuBarPopoverSize = CGSize(width: 360, height: 580)
    static let maxMenuBarTextLength = 15
    
    // MARK: - UI Layout Constants
    static let uiConstants = UIConstants()
    
    struct UIConstants {
        // Window dimensions
        let preferencesWindowWidth: CGFloat = 480
        let preferencesWindowHeight: CGFloat = 620
        
        // Spacing
        let largeSpacing: CGFloat = 20
        let mediumSpacing: CGFloat = 16
        let smallSpacing: CGFloat = 12
        let tinySpacing: CGFloat = 8
        
        // Corner radius
        let largeCornerRadius: CGFloat = 20
        let mediumCornerRadius: CGFloat = 16
        let smallCornerRadius: CGFloat = 12
        
        // Font sizes
        let titleFontSize: CGFloat = 32
        let headerFontSize: CGFloat = 18
        let bodyFontSize: CGFloat = 16
        let captionFontSize: CGFloat = 14
        let smallFontSize: CGFloat = 12
        
        // Icon sizes
        let statusBarIconSize: CGFloat = 16
        let statusIconSize: CGFloat = 32
        
        // Padding
        let windowPadding: CGFloat = 24
        let sectionPadding: CGFloat = 16
        
        // Button dimensions
        let buttonMinWidth: CGFloat = 200
        let buttonHeight: CGFloat = 44
        
        // Notification settings
        let notificationQuietHour: Int = 20 // 8 PM
    }
    
    // MARK: - Subscription Detection
    static let subscriptionThresholds = SubscriptionThresholds()
    
    // MARK: - Notification Settings
    static let notificationThresholds = NotificationThresholds()
    
    // MARK: - Performance
    static let animationDuration: TimeInterval = 0.3
    static let particleCount = 6
    
    // MARK: - Colors
    static let usageColors = UsageColors()
}

// MARK: - Supporting Types

struct SubscriptionThresholds {
    let freePlanMax = 100
    let basicPlanMin = 150
    let basicPlanMax = 1500
    let standardPlanMin = 2500
    let proPlanVoiceLimit = 999999
    let proPlanCodebaseIndices = 40
}

struct NotificationThresholds {
    let warningPercentage = 0.7
    let criticalPercentage = 0.9
    let enableNotifications = true
}

struct UsageColors {
    let healthy = "Green"
    let warning = "Orange" 
    let critical = "Red"
    let unlimited = "Green"
}