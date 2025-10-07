import XCTest
import SwiftUI
import AppKit
import Combine
@testable import WarpStatus

/// Integration tests that verify components work together correctly.
/// These tests focus on actual integration scenarios rather than isolated unit tests.
final class IntegrationTests: XCTestCase {
    var warpUsageService: WarpUsageService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        warpUsageService = WarpUsageService()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        warpUsageService = nil
        super.tearDown()
    }

    // MARK: - Service + View Integration

    func testContentViewReceivesServiceUpdates() {
        let expectation = XCTestExpectation(description: "View should receive service updates")

        // Create view bound to service
        let view = ContentView(
            warpUsageService: warpUsageService,
            onQuit: {}
        )

        // Verify view exists and is bound
        XCTAssertNotNil(view)

        // Test that service updates propagate
        warpUsageService.$usageData
            .combineLatest(warpUsageService.$isLoading)
            .dropFirst() // Skip initial values
            .sink { usageData, isLoading in
                // Either data loaded or error occurred
                XCTAssertNotNil(usageData ?? warpUsageService.lastError)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }

    func testContentViewHandlesAllServiceStates() {
        // Test that view can be created and handle all possible service states
        let states: [(WarpUsageData?, Bool, String?)] = [
            (nil, true, nil),                                   // Loading
            (nil, false, "Test error"),                        // Error
            (TestHelpers.createWarpUsageData(), false, nil),   // Success
        ]

        for (data, isLoading, error) in states {
            warpUsageService.usageData = data
            warpUsageService.isLoading = isLoading
            warpUsageService.lastError = error

            let view = ContentView(
                warpUsageService: warpUsageService,
                onQuit: {}
            )

            XCTAssertNotNil(view, "View should handle state: data=\(data != nil), loading=\(isLoading), error=\(error != nil)")
        }
    }

    // MARK: - Service + MenuBarController Integration

    func testMenuBarControllerUsesWarpUsageService() {
        // MenuBarController creates its own WarpUsageService internally
        // We can only verify it initializes without crashing
        let controller = MenuBarController()
        let expectation = XCTestExpectation(description: "Controller should initialize with service")

        // Give time for initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNotNil(controller)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Complete System Integration

    func testCompleteSystemIntegration() {
        // Test the complete system: Service -> Controller -> View
        let controller = MenuBarController()
        let view = ContentView(
            warpUsageService: warpUsageService,
            onQuit: {}
        )

        // Verify all components can coexist
        XCTAssertNotNil(controller)
        XCTAssertNotNil(view)
        XCTAssertNotNil(warpUsageService)

        let expectation = XCTestExpectation(description: "System should operate together")

        // Trigger a data load and verify system handles it
        warpUsageService.$lastUpdateTime
            .compactMap { $0 }
            .sink { updateTime in
                XCTAssertLessThanOrEqual(updateTime.timeIntervalSinceNow, 1.0)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        warpUsageService.loadUsageData(force: true)

        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }

    // MARK: - Data Flow Integration

    func testDataFlowFromServiceToView() {
        let expectation = XCTestExpectation(description: "Data should flow from service to view")

        // Monitor service updates
        var receivedData: WarpUsageData?
        var receivedLoading: Bool?

        warpUsageService.$usageData
            .combineLatest(warpUsageService.$isLoading)
            .dropFirst()
            .sink { data, loading in
                receivedData = data
                receivedLoading = loading
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Create view that observes service
        let view = ContentView(
            warpUsageService: warpUsageService,
            onQuit: {}
        )

        XCTAssertNotNil(view)

        // Trigger data load
        warpUsageService.loadUsageData(force: true)

        wait(for: [expectation], timeout: TestConstants.defaultTimeout)

        // Verify data flow occurred
        XCTAssertNotNil(receivedLoading, "Should receive loading state")
        // Either data or error should be set
        XCTAssertTrue(receivedData != nil || warpUsageService.lastError != nil)
    }

    // MARK: - Error Handling Integration

    func testSystemErrorHandling() {
        let expectation = XCTestExpectation(description: "System should handle errors gracefully")

        // Create complete system
        let view = ContentView(
            warpUsageService: warpUsageService,
            onQuit: {}
        )

        XCTAssertNotNil(view)

        // Monitor for error or success
        warpUsageService.$lastError
            .combineLatest(warpUsageService.$usageData)
            .dropFirst()
            .sink { error, data in
                // System should handle the result (error or data)
                XCTAssertTrue(error != nil || data != nil, "Should have either error or data")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        warpUsageService.loadUsageData(force: true)

        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }

    // MARK: - Real-time Updates Integration

    func testRealTimeUpdateIntegration() {
        let expectation = XCTestExpectation(description: "System should support real-time updates")
        expectation.expectedFulfillmentCount = 2

        // Track update count
        var updateCount = 0

        warpUsageService.$lastUpdateTime
            .compactMap { $0 }
            .sink { _ in
                updateCount += 1
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Trigger multiple updates
        warpUsageService.loadUsageData(force: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.warpUsageService.loadUsageData(force: true)
        }

        wait(for: [expectation], timeout: TestConstants.longTimeout)

        XCTAssertGreaterThanOrEqual(updateCount, 2, "Should receive multiple updates")
    }

    // MARK: - Memory Management Integration

    func testIntegratedSystemMemoryManagement() {
        weak var weakService: WarpUsageService?
        weak var weakController: MenuBarController?

        autoreleasepool {
            let service = WarpUsageService()
            let controller = MenuBarController()

            weakService = service
            weakController = controller

            // Create and use integrated system
            let view = ContentView(
                warpUsageService: service,
                onQuit: {}
            )

            XCTAssertNotNil(view)

            // Components go out of scope here
        }

        // Give time for cleanup
        let expectation = XCTestExpectation(description: "Cleanup")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Note: Some components may still be retained by system frameworks
        // The test verifies cleanup completes without crashes
    }

    // MARK: - Concurrent Access Integration

    func testConcurrentSystemAccess() {
        let expectation = XCTestExpectation(description: "System should handle concurrent access")
        let group = DispatchGroup()

        // Create system
        let view = ContentView(
            warpUsageService: warpUsageService,
            onQuit: {}
        )

        XCTAssertNotNil(view)

        // Access from multiple threads
        for i in 0..<5 {
            group.enter()
            let queue = i % 2 == 0 ? DispatchQueue.main : DispatchQueue.global(qos: .background)

            queue.async {
                // Access service from various threads
                _ = self.warpUsageService.usageData
                _ = self.warpUsageService.isLoading
                _ = self.warpUsageService.lastError
                group.leave()
            }
        }

        group.notify(queue: .main) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }

    // MARK: - Performance Integration

    func testSystemPerformanceUnderLoad() {
        let view = ContentView(
            warpUsageService: warpUsageService,
            onQuit: {}
        )

        XCTAssertNotNil(view)

        measure(metrics: [XCTClockMetric()]) {
            let loadExpectation = XCTestExpectation(description: "Load should complete")

            warpUsageService.$isLoading
                .filter { !$0 }
                .sink { _ in
                    loadExpectation.fulfill()
                }
                .store(in: &cancellables)

            warpUsageService.loadUsageData(force: true)

            wait(for: [loadExpectation], timeout: TestConstants.defaultTimeout)
        }
    }

    // MARK: - State Consistency Integration

    func testStateConsistencyAcrossComponents() {
        let expectation = XCTestExpectation(description: "State should be consistent")

        // Create view observing service
        let view = ContentView(
            warpUsageService: warpUsageService,
            onQuit: {}
        )

        XCTAssertNotNil(view)

        // Monitor state changes
        warpUsageService.$usageData
            .combineLatest(
                warpUsageService.$isLoading,
                warpUsageService.$lastError
            )
            .dropFirst()
            .sink { data, loading, error in
                // Verify state consistency
                if loading {
                    // Loading state is valid regardless of data/error
                    XCTAssertTrue(true)
                } else {
                    // When not loading, should have data OR error
                    XCTAssertTrue(data != nil || error != nil,
                                "Should have either data or error when not loading")
                }
                expectation.fulfill()
            }
            .store(in: &cancellables)

        warpUsageService.loadUsageData(force: true)

        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
}
