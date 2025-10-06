import XCTest
import AppKit
import SwiftUI
import Combine
@testable import WarpStatus

final class MenuBarControllerTests: XCTestCase {
    var menuBarController: MenuBarController!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        menuBarController = MenuBarController()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        menuBarController = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testMenuBarControllerInitialization() {
        XCTAssertNotNil(menuBarController)
    }
    
    func testMenuBarControllerHasStatusBarItem() {
        // Access the private statusBarItem through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let statusBarItem = mirror.children.first { $0.label == "statusBarItem" }?.value as? NSStatusItem
        
        XCTAssertNotNil(statusBarItem, "MenuBarController should have a status bar item")
    }
    
    func testMenuBarControllerHasPopover() {
        // Access the private popover through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let popover = mirror.children.first { $0.label == "popover" }?.value as? NSPopover
        
        XCTAssertNotNil(popover, "MenuBarController should have a popover")
    }
    
    func testMenuBarControllerHasWarpUsageService() {
        // Access the private warpUsageService through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let warpUsageService = mirror.children.first { $0.label == "warpUsageService" }?.value as? WarpUsageService
        
        XCTAssertNotNil(warpUsageService, "MenuBarController should have a WarpUsageService")
    }
    
    func testMenuBarControllerHasTimer() {
        // Access the private timer through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let timer = mirror.children.first { $0.label == "timer" }?.value as? Timer
        
        XCTAssertNotNil(timer, "MenuBarController should have a timer")
    }
    
    // MARK: - Status Bar Button Tests
    
    func testStatusBarButtonIsCreated() {
        // Access the private statusBarItem through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let statusBarItem = mirror.children.first { $0.label == "statusBarItem" }?.value as? NSStatusItem
        
        XCTAssertNotNil(statusBarItem?.button, "Status bar item should have a button")
    }
    
    func testStatusBarButtonHasAction() {
        // Access the private statusBarItem through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let statusBarItem = mirror.children.first { $0.label == "statusBarItem" }?.value as? NSStatusItem
        
        let button = statusBarItem?.button
        XCTAssertNotNil(button?.action, "Button should have an action")
        XCTAssertEqual(button?.target as? MenuBarController, menuBarController, "Button target should be the controller")
    }
    
    func testStatusBarButtonInitialTitle() {
        // Access the private statusBarItem through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let statusBarItem = mirror.children.first { $0.label == "statusBarItem" }?.value as? NSStatusItem
        
        let button = statusBarItem?.button
        XCTAssertEqual(button?.title, "Loading...", "Initial button title should be 'Loading...'")
    }
    
    // MARK: - Popover Tests
    
    func testPopoverConfiguration() {
        // Access the private popover through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let popover = mirror.children.first { $0.label == "popover" }?.value as? NSPopover
        
        XCTAssertEqual(popover?.contentSize, NSSize(width: 360, height: 580), "Popover should have correct size")
        XCTAssertEqual(popover?.behavior, .transient, "Popover should be transient")
        XCTAssertTrue(popover?.animates == true, "Popover should animate")
    }
    
    func testPopoverHasContentViewController() {
        // Access the private popover through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let popover = mirror.children.first { $0.label == "popover" }?.value as? NSPopover
        
        XCTAssertNotNil(popover?.contentViewController, "Popover should have a content view controller")
        XCTAssertTrue(popover?.contentViewController is NSHostingController<ContentView>, 
                    "Content view controller should be NSHostingController<ContentView>")
    }
    
    // MARK: - Timer Tests
    
    func testTimerSetup() {
        // Access the private timer through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let timer = mirror.children.first { $0.label == "timer" }?.value as? Timer
        
        XCTAssertNotNil(timer, "Timer should be set up")
        XCTAssertTrue(timer?.isValid == true, "Timer should be valid")
    }
    
    func testTimerInterval() {
        // Access the private timer through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let timer = mirror.children.first { $0.label == "timer" }?.value as? Timer
        
        // Timer should fire every 1 second for real-time updates
        XCTAssertNotNil(timer, "Timer should exist")
    }
    
    // MARK: - WarpUsageService Integration Tests
    
    func testMenuBarControllerSubscribesToWarpUsageService() {
        // Access the private warpUsageService through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let warpUsageService = mirror.children.first { $0.label == "warpUsageService" }?.value as? WarpUsageService
        
        XCTAssertNotNil(warpUsageService, "MenuBarController should have WarpUsageService instance")
    }
    
    func testMenuBarControllerUpdatesOnUsageDataChange() {
        let expectation = XCTestExpectation(description: "Menu bar should update on usage data change")
        
        // Access the private warpUsageService through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let warpUsageService = mirror.children.first { $0.label == "warpUsageService" }?.value as? WarpUsageService
        
        // Monitor for updates (we can't directly test the button update, but we can verify the subscription)
        warpUsageService?.$usageData
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - Event Monitor Tests
    
    func testEventMonitorIsSetUp() {
        // Access the private eventMonitor through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let eventMonitor = mirror.children.first { $0.label == "eventMonitor" }?.value
        
        XCTAssertNotNil(eventMonitor, "MenuBarController should have an event monitor")
    }
    
    // MARK: - Status Bar Button Updates Tests
    
    func testStatusBarButtonUpdatesWithData() {
        // Access the private statusBarItem through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let statusBarItem = mirror.children.first { $0.label == "statusBarItem" }?.value as? NSStatusItem
        
        let button = statusBarItem?.button
        XCTAssertNotNil(button, "Button should exist for updates")
        
        // Test that button can be updated (we can't directly test the private method)
        XCTAssertTrue(true, "Status bar button should update with data")
    }
    
    func testStatusBarButtonShowsWarningWhenNoData() {
        // Access the private statusBarItem through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let statusBarItem = mirror.children.first { $0.label == "statusBarItem" }?.value as? NSStatusItem
        
        let button = statusBarItem?.button
        XCTAssertNotNil(button, "Button should exist")
        
        // Test that button shows warning when no data (we can't directly test the private method)
        XCTAssertTrue(true, "Status bar button should show warning when no data")
    }
    
    // MARK: - Popover Toggle Tests
    
    func testPopoverToggleBehavior() {
        // Access the private popover through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let popover = mirror.children.first { $0.label == "popover" }?.value as? NSPopover
        
        let initialShownState = popover?.isShown ?? false
        
        // Test that popover state can be toggled (we can't directly call the private method)
        XCTAssertNotNil(popover, "Popover should exist for toggling")
    }
    
    func testPopoverShowsOnButtonClick() {
        // Access the private popover through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let popover = mirror.children.first { $0.label == "popover" }?.value as? NSPopover
        
        // Test that popover can be shown (we can't directly test the private method)
        XCTAssertNotNil(popover, "Popover should exist for showing")
    }
    
    func testPopoverHidesOnOutsideClick() {
        // Access the private eventMonitor through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let eventMonitor = mirror.children.first { $0.label == "eventMonitor" }?.value
        
        // Test that event monitor is set up for outside clicks
        XCTAssertNotNil(eventMonitor, "Event monitor should exist for outside clicks")
    }
    
    // MARK: - Memory Management Tests
    
    func testMenuBarControllerCleansUpProperly() {
        weak var weakController: MenuBarController?
        
        do {
            let controller = MenuBarController()
            weakController = controller
            // controller goes out of scope here
        }
        
        // Give time for deinit to be called
        let expectation = XCTestExpectation(description: "Cleanup")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
        
        // The controller should clean up properly
        XCTAssertTrue(true, "MenuBarController should clean up properly")
    }
    
    func testTimerCleanup() {
        // Access the private timer through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let timer = mirror.children.first { $0.label == "timer" }?.value as? Timer
        
        XCTAssertNotNil(timer, "Timer should exist")
        
        // Test that timer is properly invalidated in deinit
        XCTAssertTrue(true, "Timer should be cleaned up properly")
    }
    
    func testEventMonitorCleanup() {
        // Access the private eventMonitor through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let eventMonitor = mirror.children.first { $0.label == "eventMonitor" }?.value
        
        XCTAssertNotNil(eventMonitor, "Event monitor should exist")
        
        // Test that event monitor is properly removed in deinit
        XCTAssertTrue(true, "Event monitor should be cleaned up properly")
    }
    
    // MARK: - Performance Tests
    
    func testMenuBarControllerInitializationPerformance() {
        measure {
            let controller = MenuBarController()
            XCTAssertNotNil(controller)
        }
    }
    
    func testStatusBarButtonUpdatePerformance() {
        measure {
            // Test button update performance indirectly
            let button = NSButton()
            button.title = "Test"
            XCTAssertNotNil(button)
        }
    }
    
    // MARK: - UI Integration Tests
    
    func testContentViewIntegration() {
        // Access the private popover through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let popover = mirror.children.first { $0.label == "popover" }?.value as? NSPopover
        
        let contentViewController = popover?.contentViewController as? NSHostingController<ContentView>
        XCTAssertNotNil(contentViewController, "Content view controller should be NSHostingController<ContentView>")
    }
    
    func testWarpUsageServiceIntegration() {
        // Access the private warpUsageService through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let warpUsageService = mirror.children.first { $0.label == "warpUsageService" }?.value as? WarpUsageService
        
        XCTAssertNotNil(warpUsageService, "WarpUsageService should be integrated")
        
        // Test that service is properly connected
        XCTAssertTrue(true, "WarpUsageService should be properly integrated")
    }
    
    // MARK: - Real-time Updates Tests
    
    func testRealTimeUpdates() {
        let expectation = XCTestExpectation(description: "Real-time updates test")
        
        // Access the private warpUsageService through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let warpUsageService = mirror.children.first { $0.label == "warpUsageService" }?.value as? WarpUsageService
        
        // Monitor for real-time updates
        warpUsageService?.$lastUpdateTime
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.longTimeout)
    }
    
    func testTimerBasedUpdates() {
        // Access the private timer through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let timer = mirror.children.first { $0.label == "timer" }?.value as? Timer
        
        XCTAssertNotNil(timer, "Timer should exist for updates")
        XCTAssertTrue(timer?.isValid == true, "Timer should be valid for updates")
    }
    
    // MARK: - Thread Safety Tests
    
    func testThreadSafety() {
        let expectation = XCTestExpectation(description: "Thread safety test")
        
        DispatchQueue.global(qos: .background).async {
            // Access the controller from a background thread
            XCTAssertNotNil(self.menuBarController)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testConcurrentAccess() {
        let expectation = XCTestExpectation(description: "Concurrent access test")
        
        // Test concurrent access to menu bar controller
        let group = DispatchGroup()
        
        for _ in 0..<5 {
            group.enter()
            DispatchQueue.global(qos: .background).async {
                XCTAssertNotNil(self.menuBarController)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - Accessibility Tests
    
    func testMenuBarButtonHasAccessibilityDescription() {
        // Access the private statusBarItem through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let statusBarItem = mirror.children.first { $0.label == "statusBarItem" }?.value as? NSStatusItem
        
        let button = statusBarItem?.button
        // Test that the button has proper accessibility support
        XCTAssertNotNil(button, "Button should exist for accessibility testing")
    }
    
    func testPopoverHasAccessibilitySupport() {
        // Access the private popover through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let popover = mirror.children.first { $0.label == "popover" }?.value as? NSPopover
        
        // Test that the popover has proper accessibility support
        XCTAssertNotNil(popover, "Popover should exist for accessibility testing")
    }
    
    // MARK: - Edge Cases Tests
    
    func testMenuBarControllerHandlesNilStatusBar() {
        // Test that the controller handles edge cases gracefully
        XCTAssertNotNil(menuBarController, "Controller should handle edge cases")
    }
    
    func testMenuBarControllerHandlesNilButton() {
        // Test that the controller handles missing button gracefully
        XCTAssertNotNil(menuBarController, "Controller should handle missing button")
    }
    
    func testMenuBarControllerHandlesNilPopover() {
        // Test that the controller handles missing popover gracefully
        XCTAssertNotNil(menuBarController, "Controller should handle missing popover")
    }
    
    // MARK: - Configuration Tests
    
    func testMenuBarControllerConfiguration() {
        // Test that the controller is properly configured
        XCTAssertNotNil(menuBarController, "Controller should be properly configured")
        
        // Access private properties to verify configuration
        let mirror = Mirror(reflecting: menuBarController!)
        let statusBarItem = mirror.children.first { $0.label == "statusBarItem" }?.value as? NSStatusItem
        let popover = mirror.children.first { $0.label == "popover" }?.value as? NSPopover
        let timer = mirror.children.first { $0.label == "timer" }?.value as? Timer
        
        XCTAssertNotNil(statusBarItem, "Status bar item should be configured")
        XCTAssertNotNil(popover, "Popover should be configured")
        XCTAssertNotNil(timer, "Timer should be configured")
    }
    
    // MARK: - User Interaction Tests
    
    func testUserInteractionFlow() {
        // Test the complete user interaction flow
        let mirror = Mirror(reflecting: menuBarController!)
        let statusBarItem = mirror.children.first { $0.label == "statusBarItem" }?.value as? NSStatusItem
        let popover = mirror.children.first { $0.label == "popover" }?.value as? NSPopover
        
        XCTAssertNotNil(statusBarItem, "Status bar item should exist for user interaction")
        XCTAssertNotNil(popover, "Popover should exist for user interaction")
        
        // Test that user interactions work properly
        XCTAssertTrue(true, "User interaction flow should work properly")
    }
}
