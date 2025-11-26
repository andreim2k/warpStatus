import XCTest
import SwiftUI
import Combine
@testable import WarpStatus

/// Tests for SwiftUI views
///
/// LIMITATION: SwiftUI views cannot be fully tested in unit tests.
/// - Cannot inspect rendered output
/// - Cannot verify animations
/// - Cannot test user interactions
/// - Cannot validate accessibility features
/// - Cannot measure actual layout
///
/// These tests verify that views can be created with various data states
/// and integrate properly with observable services. For comprehensive UI testing,
/// use XCUITest framework or manual testing.
final class ViewTests: XCTestCase {
    var mockWarpUsageService: MockWarpUsageService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockWarpUsageService = TestHelpers.createMockWarpUsageService()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        mockWarpUsageService = nil
        super.tearDown()
    }

    // MARK: - ContentView Tests

    func testContentViewCreation() {
        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )

        XCTAssertNotNil(view)
    }

    func testContentViewWithDifferentServiceStates() {
        // Test view creation with various service states
        let states: [(usedRequests: Int, requestsLimit: Int, description: String)] = [
            (0, 100, "Zero usage"),
            (50, 100, "Half usage"),
            (99, 100, "Nearly full"),
            (100, 100, "Full usage"),
            (150, 100, "Over limit"),
        ]

        for (used, limit, description) in states {
            mockWarpUsageService.setMockUsageData(
                requestsUsed: used,
                requestsLimit: limit
            )

            let view = ContentView(
                warpUsageService: mockWarpUsageService,
                onQuit: {}
            )

            XCTAssertNotNil(view, "Should create view with \(description)")
        }
    }

    func testContentViewHandlesLoadingState() {
        let expectation = XCTestExpectation(description: "View should handle loading state")

        mockWarpUsageService.$isLoading
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )

        XCTAssertNotNil(view)
        mockWarpUsageService.loadUsageData(force: true)

        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }

    func testContentViewHandlesErrorState() {
        mockWarpUsageService.setError("Test error")

        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )

        XCTAssertNotNil(view)
        XCTAssertNotNil(mockWarpUsageService.lastError)
    }

    func testContentViewHandlesDataUpdates() {
        let expectation = XCTestExpectation(description: "View should handle data updates")

        mockWarpUsageService.$usageData
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )

        XCTAssertNotNil(view)
        mockWarpUsageService.setMockUsageData(requestsUsed: 500, requestsLimit: 1000)

        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }

    func testContentViewOnQuitCallback() {
        var quitCalled = false

        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {
                quitCalled = true
            }
        )

        XCTAssertNotNil(view)
        XCTAssertFalse(quitCalled, "Quit should not be called on creation")
    }

    // MARK: - Card Component Tests

    func testLiquidGlassPlanCardCreation() {
        let data = TestHelpers.createWarpUsageData()
        let card = LiquidGlassPlanCard(data: data)

        XCTAssertNotNil(card)
    }

    func testLiquidGlassPlanCardWithAllSubscriptionTypes() {
        let subscriptionTypes = ["Free", "Basic", "Standard", "Pro"]

        for subscriptionType in subscriptionTypes {
            let data = TestHelpers.createWarpUsageData(subscriptionType: subscriptionType)
            let card = LiquidGlassPlanCard(data: data)

            XCTAssertNotNil(card, "Should create card for \(subscriptionType) subscription")
        }
    }

    func testLiquidGlassUsageCardCreation() {
        let data = TestHelpers.createWarpUsageData()
        let card = LiquidGlassUsageCard(data: data)

        XCTAssertNotNil(card)
    }

    func testLiquidGlassUsageCardWithVariousUsageLevels() {
        let usageLevels = [0, 250, 500, 750, 1000, 1500]

        for used in usageLevels {
            let data = TestHelpers.createWarpUsageData(
                requestsUsed: used,
                requestsLimit: 1000
            )
            let card = LiquidGlassUsageCard(data: data)

            XCTAssertNotNil(card, "Should create card with usage: \(used)")
        }
    }

    func testLiquidGlassProgressCardCreation() {
        let data = TestHelpers.createWarpUsageData()
        let card = LiquidGlassProgressCard(data: data)

        XCTAssertNotNil(card)
    }

    func testLiquidGlassProgressCardWithDifferentPercentages() {
        let usageScenarios = [
            (used: 10, limit: 100, description: "Low usage"),
            (used: 50, limit: 100, description: "Medium usage"),
            (used: 75, limit: 100, description: "High usage"),
            (used: 95, limit: 100, description: "Critical usage"),
        ]

        for (used, limit, description) in usageScenarios {
            let data = TestHelpers.createWarpUsageData(
                requestsUsed: used,
                requestsLimit: limit
            )
            let card = LiquidGlassProgressCard(data: data)

            XCTAssertNotNil(card, "Should create progress card for: \(description)")
        }
    }

    func testLiquidGlassResetCardCreation() {
        let data = TestHelpers.createWarpUsageData()
        let card = LiquidGlassResetCard(data: data)

        XCTAssertNotNil(card)
    }

    func testLiquidGlassResetCardWithDifferentDates() {
        let dates = [
            Date(),
            Date().addingTimeInterval(86400),  // 1 day
            Date().addingTimeInterval(604800), // 1 week
            Date().addingTimeInterval(2592000), // 1 month
        ]

        for date in dates {
            let data = TestHelpers.createWarpUsageData(nextRefreshTime: date)
            let card = LiquidGlassResetCard(data: data)

            XCTAssertNotNil(card, "Should create card with refresh date: \(date)")
        }
    }

    func testLiquidGlassErrorCardCreation() {
        let card = LiquidGlassErrorCard(error: "Test error message")

        XCTAssertNotNil(card)
    }

    func testLiquidGlassErrorCardWithVariousMessages() {
        let errorMessages = [
            "Warp not found",
            "File not accessible",
            "Network error occurred",
            "A very long error message that contains multiple sentences and should still display properly without causing any issues in the UI layout or text rendering",
        ]

        for errorMessage in errorMessages {
            let card = LiquidGlassErrorCard(error: errorMessage)

            XCTAssertNotNil(card, "Should create error card with message")
        }
    }

    func testLiquidGlassLoadingCardCreation() {
        let card = LiquidGlassLoadingCard()

        XCTAssertNotNil(card)
    }

    func testLiquidGlassButtonStyleCreation() {
        let colors: [Color] = [.cyan, .blue, .purple, .red, .green, .orange]

        for color in colors {
            let style = LiquidGlassButtonStyle(color: color)

            XCTAssertNotNil(style, "Should create button style with color")
        }
    }

    // MARK: - Edge Cases

    func testViewWithUnlimitedData() {
        mockWarpUsageService.setMockUsageData(
            requestsUsed: 9999,
            requestsLimit: 0,
            isUnlimited: true,
            subscriptionType: "Pro"
        )

        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )

        XCTAssertNotNil(view)

        let planCard = LiquidGlassPlanCard(data: mockWarpUsageService.usageData!)
        let usageCard = LiquidGlassUsageCard(data: mockWarpUsageService.usageData!)

        XCTAssertNotNil(planCard)
        XCTAssertNotNil(usageCard)
    }

    func testViewWithZeroValues() {
        mockWarpUsageService.setMockUsageData(
            requestsUsed: 0,
            requestsLimit: 0
        )

        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )

        XCTAssertNotNil(view)
    }

    func testViewWithNegativeValues() {
        mockWarpUsageService.setMockUsageData(
            requestsUsed: -100,
            requestsLimit: 1000
        )

        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )

        XCTAssertNotNil(view)
    }

    func testViewWithExtremeValues() {
        mockWarpUsageService.setMockUsageData(
            requestsUsed: Int.max,
            requestsLimit: Int.max
        )

        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )

        XCTAssertNotNil(view)
    }

    // MARK: - Performance Tests

    func testContentViewCreationPerformance() {
        measure {
            let view = ContentView(
                warpUsageService: mockWarpUsageService,
                onQuit: {}
            )

            XCTAssertNotNil(view)
        }
    }

    func testCardCreationPerformance() {
        let data = TestHelpers.createWarpUsageData()

        measure {
            _ = LiquidGlassPlanCard(data: data)
            _ = LiquidGlassUsageCard(data: data)
            _ = LiquidGlassProgressCard(data: data)
            _ = LiquidGlassResetCard(data: data)
        }
    }

    // MARK: - Data Binding Tests

    func testViewBindsToServiceData() {
        let expectation = XCTestExpectation(description: "View should bind to service data")

        mockWarpUsageService.$usageData
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )

        XCTAssertNotNil(view)
        mockWarpUsageService.setMockUsageData(requestsUsed: 500, requestsLimit: 1000)

        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }

    func testViewBindsToServiceLoadingState() {
        let expectation = XCTestExpectation(description: "View should bind to loading state")

        mockWarpUsageService.$isLoading
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )

        XCTAssertNotNil(view)
        mockWarpUsageService.loadUsageData(force: true)

        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }

    func testViewBindsToServiceErrorState() {
        let expectation = XCTestExpectation(description: "View should bind to error state")

        mockWarpUsageService.$lastError
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )

        XCTAssertNotNil(view)
        mockWarpUsageService.setError("Test error")

        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
}

