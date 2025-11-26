import XCTest
@testable import WarpStatus

/// Tests for AppConfiguration and related configuration structures
final class ConfigurationTests: XCTestCase {
    
    func testAppConfigurationExists() {
        XCTAssertNotNil(AppConfiguration.self)
    }
    
    func testRefreshIntervalConfiguration() {
        XCTAssertEqual(AppConfiguration.refreshInterval, 1.0)
        XCTAssertGreaterThan(AppConfiguration.refreshInterval, 0)
    }
    
    func testRetryConfiguration() {
        XCTAssertEqual(AppConfiguration.retryAttempts, 3)
        XCTAssertEqual(AppConfiguration.retryDelay, 1.0)
    }
    
    func testSupportedPlistNames() {
        let expectedNames = [
            "dev.warp.Warp-Stable.plist",
            "dev.warp.Warp-Beta.plist", 
            "dev.warp.Warp-Nightly.plist",
            "dev.warp.Warp.plist"
        ]
        
        XCTAssertEqual(AppConfiguration.supportedPlistNames.count, expectedNames.count)
        for (actual, expected) in zip(AppConfiguration.supportedPlistNames, expectedNames) {
            XCTAssertEqual(actual, expected)
        }
    }
    
    func testMenuBarPopoverSize() {
        XCTAssertEqual(AppConfiguration.menuBarPopoverSize.width, 360)
        XCTAssertEqual(AppConfiguration.menuBarPopoverSize.height, 580)
    }
    
    func testMaxMenuBarTextLength() {
        XCTAssertEqual(AppConfiguration.maxMenuBarTextLength, 15)
    }
    
    func testSubscriptionThresholds() {
        let thresholds = AppConfiguration.subscriptionThresholds
        
        XCTAssertEqual(thresholds.freePlanMax, 100)
        XCTAssertEqual(thresholds.basicPlanMin, 150)
        XCTAssertEqual(thresholds.basicPlanMax, 1500)
        XCTAssertEqual(thresholds.standardPlanMin, 2500)
        XCTAssertEqual(thresholds.proPlanVoiceLimit, 999999)
        XCTAssertEqual(thresholds.proPlanCodebaseIndices, 40)
    }
    
    func testNotificationThresholds() {
        let thresholds = AppConfiguration.notificationThresholds
        
        XCTAssertEqual(thresholds.warningPercentage, 0.7, accuracy: 0.001)
        XCTAssertEqual(thresholds.criticalPercentage, 0.9, accuracy: 0.001)
        XCTAssertTrue(thresholds.enableNotifications)
    }
    
    func testUsageColors() {
        let colors = AppConfiguration.usageColors
        
        XCTAssertEqual(colors.healthy, "Green")
        XCTAssertEqual(colors.warning, "Orange")
        XCTAssertEqual(colors.critical, "Red")
        XCTAssertEqual(colors.unlimited, "Green")
    }
    
    func testPreferencesDirectory() {
        let expectedPath = "\(NSHomeDirectory())/Library/Preferences/"
        XCTAssertEqual(AppConfiguration.preferencesDirectory, expectedPath)
    }
    
    func testAnimationDuration() {
        XCTAssertEqual(AppConfiguration.animationDuration, 0.3, accuracy: 0.001)
    }
    
    func testParticleCount() {
        XCTAssertEqual(AppConfiguration.particleCount, 6)
    }
    
    func testConfigurationConsistency() {
        // Verify that all configuration values are reasonable
        XCTAssertGreaterThan(AppConfiguration.refreshInterval, 0)
        XCTAssertGreaterThan(AppConfiguration.retryAttempts, 0)
        XCTAssertGreaterThan(AppConfiguration.retryDelay, 0)
        XCTAssertGreaterThan(AppConfiguration.maxMenuBarTextLength, 0)
        XCTAssertGreaterThan(AppConfiguration.menuBarPopoverSize.width, 0)
        XCTAssertGreaterThan(AppConfiguration.menuBarPopoverSize.height, 0)
        XCTAssertGreaterThan(AppConfiguration.particleCount, 0)
    }
}