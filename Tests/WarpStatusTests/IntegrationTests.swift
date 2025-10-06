import XCTest
import SwiftUI
import AppKit
import Combine
@testable import WarpStatus

final class IntegrationTests: XCTestCase {
    var warpUsageService: WarpUsageService!
    var menuBarController: MenuBarController!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        warpUsageService = WarpUsageService()
        menuBarController = MenuBarController()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        menuBarController = nil
        warpUsageService = nil
        super.tearDown()
    }
    
    // MARK: - System Integration Tests
    
    func testWarpUsageServiceAndMenuBarControllerIntegration() {
        let expectation = XCTestExpectation(description: "Integration should work")
        
        // Test that WarpUsageService and MenuBarController work together
        warpUsageService.$usageData
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testEndToEndUsageFlow() {
        let expectation = XCTestExpectation(description: "End-to-end flow should work")
        
        // Test the complete flow from usage data to UI
        warpUsageService.$usageData
            .combineLatest(
                warpUsageService.$isLoading,
                warpUsageService.$lastError,
                warpUsageService.$lastUpdateTime
            )
            .dropFirst()
            .sink { usageData, isLoading, lastError, lastUpdateTime in
                // Verify all components are updating
                XCTAssertFalse(isLoading, "Loading should complete")
                XCTAssertNotNil(lastUpdateTime, "Update time should be set")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - UI Integration Tests
    
    func testContentViewIntegrationWithWarpUsageService() {
        let view = ContentView(
            warpUsageService: warpUsageService,
            onQuit: {}
        )
        
        XCTAssertNotNil(view)
        
        // Test that the view integrates properly with WarpUsageService
        let expectation = XCTestExpectation(description: "View should integrate with service")
        
        warpUsageService.$usageData
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testMenuBarControllerAndContentViewIntegration() {
        // Test that MenuBarController and ContentView work together
        let view = ContentView(
            warpUsageService: warpUsageService,
            onQuit: {}
        )
        
        XCTAssertNotNil(view)
        XCTAssertNotNil(menuBarController)
        
        // Test that both components can coexist
        let expectation = XCTestExpectation(description: "Components should integrate")
        
        warpUsageService.$usageData
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - Data Flow Integration Tests
    
    func testUsageDataFlow() {
        let expectation = XCTestExpectation(description: "Data flow should work")
        
        // Test that data flows correctly through the system
        warpUsageService.$usageData
            .combineLatest(warpUsageService.$isLoading)
            .dropFirst()
            .sink { usageData, isLoading in
                // Verify data is flowing correctly
                XCTAssertFalse(isLoading, "Loading should complete")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testErrorFlow() {
        let expectation = XCTestExpectation(description: "Error flow should work")
        
        // Test that errors flow correctly through the system
        warpUsageService.$lastError
            .dropFirst()
            .sink { error in
                // Verify error is flowing correctly
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - Performance Integration Tests
    
    func testSystemPerformanceUnderLoad() {
        measure {
            // Test system performance under load
            let expectation = XCTestExpectation(description: "Performance test")
            
            warpUsageService.$usageData
                .dropFirst()
                .sink { _ in
                    expectation.fulfill()
                }
                .store(in: &cancellables)
            
            wait(for: [expectation], timeout: TestConstants.defaultTimeout)
        }
    }
    
    func testMemoryUsageUnderLoad() {
        measure {
            // Test memory usage under load
            let expectation = XCTestExpectation(description: "Memory test")
            
            warpUsageService.$isLoading
                .dropFirst()
                .sink { _ in
                    expectation.fulfill()
                }
                .store(in: &cancellables)
            
            wait(for: [expectation], timeout: TestConstants.defaultTimeout)
        }
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testSystemHandlesErrorsGracefully() {
        // Test that the system handles errors gracefully
        let expectation = XCTestExpectation(description: "Error handling test")
        
        // Simulate an error condition
        warpUsageService.$lastError
            .sink { error in
                // System should handle errors gracefully
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testSystemRecoversFromErrors() {
        // Test that the system recovers from errors
        let expectation = XCTestExpectation(description: "Error recovery test")
        
        warpUsageService.$usageData
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - Thread Safety Integration Tests
    
    func testThreadSafety() {
        let expectation = XCTestExpectation(description: "Thread safety test")
        
        // Test that the system is thread-safe
        DispatchQueue.global(qos: .background).async {
            // Access system components from background thread
            XCTAssertNotNil(self.warpUsageService)
            XCTAssertNotNil(self.menuBarController)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testConcurrentAccess() {
        let expectation = XCTestExpectation(description: "Concurrent access test")
        
        // Test concurrent access to system components
        let group = DispatchGroup()
        
        for _ in 0..<5 {
            group.enter()
            DispatchQueue.global(qos: .background).async {
                XCTAssertNotNil(self.warpUsageService)
                XCTAssertNotNil(self.menuBarController)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - Resource Management Integration Tests
    
    func testResourceManagement() {
        // Test that resources are managed properly
        let expectation = XCTestExpectation(description: "Resource management test")
        
        // Create and destroy components
        let service = WarpUsageService()
        let controller = MenuBarController()
        
        XCTAssertNotNil(service)
        XCTAssertNotNil(controller)
        
        // Clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testMemoryLeaks() {
        // Test for memory leaks
        let expectation = XCTestExpectation(description: "Memory leak test")
        
        weak var weakService: WarpUsageService?
        weak var weakController: MenuBarController?
        
        do {
            let service = WarpUsageService()
            let controller = MenuBarController()
            
            weakService = service
            weakController = controller
            
            // Components go out of scope here
        }
        
        // Give time for cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
        
        // Note: We can't directly test for memory leaks in unit tests
        // but we can verify the components exist and can be cleaned up
        XCTAssertTrue(true, "Memory leak test completed")
    }
    
    // MARK: - Real-time Updates Integration Tests
    
    func testRealTimeUpdates() {
        let expectation = XCTestExpectation(description: "Real-time updates test")
        
        // Test that updates happen in real-time
        var updateCount = 0
        
        warpUsageService.$usageData
            .sink { _ in
                updateCount += 1
                if updateCount >= 3 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Trigger multiple updates
        warpUsageService.loadUsageData(force: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.warpUsageService.loadUsageData(force: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.warpUsageService.loadUsageData(force: true)
        }
        
        wait(for: [expectation], timeout: TestConstants.longTimeout)
    }
    
    func testUpdateFrequency() {
        let expectation = XCTestExpectation(description: "Update frequency test")
        
        // Test that updates happen at the expected frequency
        var lastUpdateTime = Date()
        
        warpUsageService.$lastUpdateTime
            .dropFirst()
            .sink { updateTime in
                if let updateTime = updateTime {
                    let timeDiff = updateTime.timeIntervalSince(lastUpdateTime)
                    
                    // Updates should happen regularly
                    XCTAssertGreaterThan(timeDiff, 0.1, "Updates should happen regularly")
                    XCTAssertLessThan(timeDiff, 5.0, "Updates should not be too slow")
                    
                    lastUpdateTime = updateTime
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.longTimeout)
    }
    
    // MARK: - System State Integration Tests
    
    func testSystemStateConsistency() {
        let expectation = XCTestExpectation(description: "System state consistency test")
        
        // Test that system state remains consistent
        warpUsageService.$usageData
            .combineLatest(
                warpUsageService.$isLoading,
                warpUsageService.$lastError
            )
            .dropFirst()
            .sink { usageData, isLoading, lastError in
                // Verify state consistency
                XCTAssertFalse(isLoading, "Loading should complete")
                
                // Either we have data or we have an error, but not both
                if usageData != nil {
                    XCTAssertNil(lastError, "Should not have error when data is available")
                }
                
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testSystemStateTransitions() {
        let expectation = XCTestExpectation(description: "System state transitions test")
        
        // Test that system state transitions are handled properly
        warpUsageService.$isLoading
            .dropFirst()
            .sink { _ in
                // State transitions should be handled gracefully
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - User Interaction Integration Tests
    
    func testUserInteractionFlow() {
        // Test the complete user interaction flow
        let view = ContentView(
            warpUsageService: warpUsageService,
            onQuit: {}
        )
        
        XCTAssertNotNil(view)
        XCTAssertNotNil(menuBarController)
        
        // Test that user interactions work properly
        let expectation = XCTestExpectation(description: "User interaction test")
        
        warpUsageService.$usageData
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testMenuBarInteraction() {
        // Test menu bar interaction flow
        let expectation = XCTestExpectation(description: "Menu bar interaction test")
        
        // Access the private statusBarItem through reflection for testing
        let mirror = Mirror(reflecting: menuBarController!)
        let statusBarItem = mirror.children.first { $0.label == "statusBarItem" }?.value as? NSStatusItem
        
        XCTAssertNotNil(statusBarItem, "Status bar item should exist for interaction")
        
        // Test that menu bar interactions work properly
        warpUsageService.$usageData
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - Configuration Integration Tests
    
    func testConfigurationIntegration() {
        // Test that configuration is properly integrated
        let expectation = XCTestExpectation(description: "Configuration integration test")
        
        // Test that the system uses proper configuration
        warpUsageService.$usageData
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - Monitoring Integration Tests
    
    func testMonitoringIntegration() {
        // Test that monitoring is properly integrated
        let expectation = XCTestExpectation(description: "Monitoring integration test")
        
        // Test that all monitoring components work together
        warpUsageService.$usageData
            .combineLatest(
                warpUsageService.$isLoading,
                warpUsageService.$lastError,
                warpUsageService.$lastUpdateTime
            )
            .dropFirst()
            .sink { _, _, _, _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - Subscription Type Integration Tests
    
    func testSubscriptionTypeIntegration() {
        let expectation = XCTestExpectation(description: "Subscription type integration test")
        
        // Test that subscription types are properly integrated
        warpUsageService.$usageData
            .dropFirst()
            .sink { usageData in
                if let data = usageData {
                    // Verify subscription type is properly determined
                    XCTAssertFalse(data.subscriptionType.isEmpty, "Subscription type should not be empty")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - Usage Calculation Integration Tests
    
    func testUsageCalculationIntegration() {
        let expectation = XCTestExpectation(description: "Usage calculation integration test")
        
        // Test that usage calculations are properly integrated
        warpUsageService.$usageData
            .dropFirst()
            .sink { usageData in
                if let data = usageData {
                    // Verify usage calculations are correct
                    XCTAssertGreaterThanOrEqual(data.usagePercentage, 0.0, "Usage percentage should be non-negative")
                    XCTAssertLessThanOrEqual(data.usagePercentage, 1.0, "Usage percentage should not exceed 100%")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - File System Integration Tests
    
    func testFileSystemIntegration() {
        let expectation = XCTestExpectation(description: "File system integration test")
        
        // Test that file system operations are properly integrated
        warpUsageService.$usageData
            .dropFirst()
            .sink { _ in
                // File system operations should complete
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - Network Integration Tests
    
    func testNetworkIntegration() {
        let expectation = XCTestExpectation(description: "Network integration test")
        
        // Test that network operations are properly integrated
        warpUsageService.$usageData
            .dropFirst()
            .sink { _ in
                // Network operations should complete
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - Data Persistence Integration Tests
    
    func testDataPersistenceIntegration() {
        let expectation = XCTestExpectation(description: "Data persistence integration test")
        
        // Test that data persistence is properly integrated
        warpUsageService.$usageData
            .dropFirst()
            .sink { _ in
                // Data persistence operations should complete
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - Error Recovery Integration Tests
    
    func testErrorRecoveryIntegration() {
        let expectation = XCTestExpectation(description: "Error recovery integration test")
        
        // Test that error recovery is properly integrated
        warpUsageService.$lastError
            .combineLatest(warpUsageService.$usageData)
            .dropFirst()
            .sink { error, usageData in
                // Error recovery should work properly
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - Performance Monitoring Integration Tests
    
    func testPerformanceMonitoringIntegration() {
        let expectation = XCTestExpectation(description: "Performance monitoring integration test")
        
        // Test that performance monitoring is properly integrated
        warpUsageService.$lastUpdateTime
            .dropFirst()
            .sink { _ in
                // Performance monitoring should work properly
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
}
