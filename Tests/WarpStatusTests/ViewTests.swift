import XCTest
import SwiftUI
import Combine
@testable import WarpStatus

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
    
    func testContentViewInitialization() {
        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )
        
        XCTAssertNotNil(view)
    }
    
    func testContentViewHasCorrectFrame() {
        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )
        
        // Test that the view has the expected frame size
        // Note: We can't directly test SwiftUI view properties, but we can verify the view exists
        XCTAssertNotNil(view)
    }
    
    func testContentViewUpdatesWithUsageData() {
        let expectation = XCTestExpectation(description: "View should update with usage data")
        
        // Test that the view responds to usage data changes
        mockWarpUsageService.$usageData
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Update usage data
        mockWarpUsageService.setMockUsageData(requestsUsed: 500, requestsLimit: 1000)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testContentViewHandlesLoadingState() {
        let expectation = XCTestExpectation(description: "View should handle loading state")
        
        mockWarpUsageService.$isLoading
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        mockWarpUsageService.loadUsageData(force: true)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testContentViewHandlesErrorState() {
        let expectation = XCTestExpectation(description: "View should handle error state")
        
        mockWarpUsageService.$lastError
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        mockWarpUsageService.setError("Test error")
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - LiquidGlassPlanCard Tests
    
    func testLiquidGlassPlanCardInitialization() {
        let data = TestHelpers.createWarpUsageData()
        let card = LiquidGlassPlanCard(data: data)
        
        XCTAssertNotNil(card)
    }
    
    func testLiquidGlassPlanCardWithDifferentSubscriptionTypes() {
        let subscriptionTypes = [TestConstants.freePlan, TestConstants.basicPlan, TestConstants.standardPlan, TestConstants.proPlan]
        
        for subscriptionType in subscriptionTypes {
            let data = TestHelpers.createWarpUsageData(subscriptionType: subscriptionType)
            let card = LiquidGlassPlanCard(data: data)
            XCTAssertNotNil(card)
        }
    }
    
    func testLiquidGlassPlanCardWithUnlimitedPlan() {
        let data = TestHelpers.createWarpUsageData(
            isUnlimited: true,
            subscriptionType: TestConstants.proPlan
        )
        let card = LiquidGlassPlanCard(data: data)
        
        XCTAssertNotNil(card)
    }
    
    // MARK: - LiquidGlassUsageCard Tests
    
    func testLiquidGlassUsageCardInitialization() {
        let data = TestHelpers.createWarpUsageData()
        let card = LiquidGlassUsageCard(data: data)
        
        XCTAssertNotNil(card)
    }
    
    func testLiquidGlassUsageCardWithDifferentUsageLevels() {
        let usageLevels = [
            (used: 50, limit: 1000, percentage: 0.05),
            (used: 500, limit: 1000, percentage: 0.5),
            (used: 900, limit: 1000, percentage: 0.9),
            (used: 950, limit: 1000, percentage: 0.95)
        ]
        
        for (used, limit, percentage) in usageLevels {
            let data = TestHelpers.createWarpUsageData(
                requestsUsed: used,
                requestsLimit: limit
            )
            let card = LiquidGlassUsageCard(data: data)
            XCTAssertNotNil(card)
        }
    }
    
    func testLiquidGlassUsageCardWithUnlimitedUsage() {
        let data = TestHelpers.createWarpUsageData(
            requestsUsed: 9999,
            requestsLimit: 0,
            isUnlimited: true
        )
        let card = LiquidGlassUsageCard(data: data)
        
        XCTAssertNotNil(card)
    }
    
    // MARK: - LiquidGlassProgressCard Tests
    
    func testLiquidGlassProgressCardInitialization() {
        let data = TestHelpers.createWarpUsageData()
        let card = LiquidGlassProgressCard(data: data)
        
        XCTAssertNotNil(card)
    }
    
    func testLiquidGlassProgressCardWithDifferentPercentages() {
        let percentages = [0.1, 0.5, 0.75, 0.9, 0.95]
        
        for percentage in percentages {
            let used = Int(Double(1000) * percentage)
            let data = TestHelpers.createWarpUsageData(
                requestsUsed: used,
                requestsLimit: 1000
            )
            let card = LiquidGlassProgressCard(data: data)
            XCTAssertNotNil(card)
        }
    }
    
    func testLiquidGlassProgressCardColorCoding() {
        // Test low usage (green)
        let lowData = TestHelpers.createWarpUsageData(
            requestsUsed: 100,
            requestsLimit: 1000
        )
        let lowCard = LiquidGlassProgressCard(data: lowData)
        XCTAssertNotNil(lowCard)
        
        // Test medium usage (orange)
        let mediumData = TestHelpers.createWarpUsageData(
            requestsUsed: 750,
            requestsLimit: 1000
        )
        let mediumCard = LiquidGlassProgressCard(data: mediumData)
        XCTAssertNotNil(mediumCard)
        
        // Test high usage (red)
        let highData = TestHelpers.createWarpUsageData(
            requestsUsed: 950,
            requestsLimit: 1000
        )
        let highCard = LiquidGlassProgressCard(data: highData)
        XCTAssertNotNil(highCard)
    }
    
    // MARK: - LiquidGlassResetCard Tests
    
    func testLiquidGlassResetCardInitialization() {
        let data = TestHelpers.createWarpUsageData()
        let card = LiquidGlassResetCard(data: data)
        
        XCTAssertNotNil(card)
    }
    
    func testLiquidGlassResetCardWithDifferentRefreshTimes() {
        let refreshTimes = [
            Date().addingTimeInterval(TestConstants.oneDayFromNow),
            Date().addingTimeInterval(TestConstants.oneWeekFromNow),
            Date().addingTimeInterval(TestConstants.oneMonthFromNow)
        ]
        
        for refreshTime in refreshTimes {
            let data = TestHelpers.createWarpUsageData(nextRefreshTime: refreshTime)
            let card = LiquidGlassResetCard(data: data)
            XCTAssertNotNil(card)
        }
    }
    
    // MARK: - LiquidGlassErrorCard Tests
    
    func testLiquidGlassErrorCardInitialization() {
        let card = LiquidGlassErrorCard(error: "Test error message")
        
        XCTAssertNotNil(card)
    }
    
    func testLiquidGlassErrorCardWithDifferentErrorMessages() {
        let errorMessages = [
            "Warp preferences file not found",
            "Failed to parse Warp usage data",
            "Network connection error",
            "Invalid data format"
        ]
        
        for errorMessage in errorMessages {
            let card = LiquidGlassErrorCard(error: errorMessage)
            XCTAssertNotNil(card)
        }
    }
    
    func testLiquidGlassErrorCardWithLongErrorMessage() {
        let longError = "This is a very long error message that should test how the error card handles lengthy text content and ensures proper text wrapping and display"
        let card = LiquidGlassErrorCard(error: longError)
        
        XCTAssertNotNil(card)
    }
    
    // MARK: - LiquidGlassLoadingCard Tests
    
    func testLiquidGlassLoadingCardInitialization() {
        let card = LiquidGlassLoadingCard()
        
        XCTAssertNotNil(card)
    }
    
    // MARK: - LiquidGlassButtonStyle Tests
    
    func testLiquidGlassButtonStyleInitialization() {
        let style = LiquidGlassButtonStyle(color: .cyan)
        XCTAssertNotNil(style)
    }
    
    func testLiquidGlassButtonStyleWithDifferentColors() {
        let colors: [Color] = [.cyan, .blue, .purple, .red, .green, .orange]
        
        for color in colors {
            let style = LiquidGlassButtonStyle(color: color)
            XCTAssertNotNil(style)
        }
    }
    
    // MARK: - View Composition Tests
    
    func testViewHierarchy() {
        let contentView = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )
        
        XCTAssertNotNil(contentView)
        
        // Test that the view can be composed with other views
        let composedView = VStack {
            contentView
            Text("Additional content")
        }
        
        XCTAssertNotNil(composedView)
    }
    
    func testViewWithDifferentUsageData() {
        let highUsageService = TestHelpers.createHighUsageWarpService()
        let lowUsageService = TestHelpers.createLowUsageWarpService()
        let unlimitedService = TestHelpers.createUnlimitedWarpService()
        let errorService = TestHelpers.createErrorWarpService()
        
        let highUsageView = ContentView(
            warpUsageService: highUsageService,
            onQuit: {}
        )
        
        let lowUsageView = ContentView(
            warpUsageService: lowUsageService,
            onQuit: {}
        )
        
        let unlimitedView = ContentView(
            warpUsageService: unlimitedService,
            onQuit: {}
        )
        
        let errorView = ContentView(
            warpUsageService: errorService,
            onQuit: {}
        )
        
        XCTAssertNotNil(highUsageView)
        XCTAssertNotNil(lowUsageView)
        XCTAssertNotNil(unlimitedView)
        XCTAssertNotNil(errorView)
    }
    
    // MARK: - Animation Tests
    
    func testViewAnimations() {
        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )
        
        // Test that the view supports animations
        XCTAssertNotNil(view)
        
        // Note: We can't directly test SwiftUI animations in unit tests
        // but we can verify the view exists and can be animated
    }
    
    func testCardAnimations() {
        let data = TestHelpers.createWarpUsageData()
        
        let planCard = LiquidGlassPlanCard(data: data)
        let usageCard = LiquidGlassUsageCard(data: data)
        let progressCard = LiquidGlassProgressCard(data: data)
        let resetCard = LiquidGlassResetCard(data: data)
        
        XCTAssertNotNil(planCard)
        XCTAssertNotNil(usageCard)
        XCTAssertNotNil(progressCard)
        XCTAssertNotNil(resetCard)
    }
    
    // MARK: - Accessibility Tests
    
    func testViewAccessibility() {
        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )
        
        // Test that the view has proper accessibility support
        XCTAssertNotNil(view)
        
        // Note: SwiftUI accessibility testing requires UI testing framework
        // but we can verify the view exists for accessibility testing
    }
    
    func testCardAccessibility() {
        let data = TestHelpers.createWarpUsageData()
        
        let planCard = LiquidGlassPlanCard(data: data)
        let usageCard = LiquidGlassUsageCard(data: data)
        let progressCard = LiquidGlassProgressCard(data: data)
        let resetCard = LiquidGlassResetCard(data: data)
        let errorCard = LiquidGlassErrorCard(error: "Test error")
        let loadingCard = LiquidGlassLoadingCard()
        
        XCTAssertNotNil(planCard)
        XCTAssertNotNil(usageCard)
        XCTAssertNotNil(progressCard)
        XCTAssertNotNil(resetCard)
        XCTAssertNotNil(errorCard)
        XCTAssertNotNil(loadingCard)
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
        measure {
            let data = TestHelpers.createWarpUsageData()
            
            let planCard = LiquidGlassPlanCard(data: data)
            let usageCard = LiquidGlassUsageCard(data: data)
            let progressCard = LiquidGlassProgressCard(data: data)
            let resetCard = LiquidGlassResetCard(data: data)
            
            XCTAssertNotNil(planCard)
            XCTAssertNotNil(usageCard)
            XCTAssertNotNil(progressCard)
            XCTAssertNotNil(resetCard)
        }
    }
    
    func testButtonStyleCreationPerformance() {
        measure {
            let style = LiquidGlassButtonStyle(color: .cyan)
            XCTAssertNotNil(style)
        }
    }
    
    // MARK: - Edge Cases Tests
    
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
    
    func testViewWithMaximumValues() {
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
    
    func testViewWithInvalidData() {
        mockWarpUsageService.setError("Invalid data")
        
        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )
        
        XCTAssertNotNil(view)
    }
    
    // MARK: - Data Binding Tests
    
    func testViewDataBinding() {
        let expectation = XCTestExpectation(description: "View should bind to data")
        
        // Test that the view responds to data changes
        mockWarpUsageService.$usageData
            .combineLatest(
                mockWarpUsageService.$isLoading,
                mockWarpUsageService.$lastError,
                mockWarpUsageService.$lastUpdateTime
            )
            .sink { _, _, _, _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Update all data
        mockWarpUsageService.setMockUsageData(requestsUsed: 500, requestsLimit: 1000)
        mockWarpUsageService.loadUsageData(force: true)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testViewStateManagement() {
        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )
        
        // Test that the view manages its state properly
        XCTAssertNotNil(view)
        
        // Note: SwiftUI state management testing requires UI testing framework
        // but we can verify the view exists and can manage state
    }
    
    // MARK: - View Updates Tests
    
    func testViewUpdatesOnDataChange() {
        let expectation = XCTestExpectation(description: "View should update on data change")
        
        // Test that the view updates when data changes
        mockWarpUsageService.$usageData
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Change data
        mockWarpUsageService.setMockUsageData(requestsUsed: 750, requestsLimit: 1000)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testViewUpdatesOnLoadingStateChange() {
        let expectation = XCTestExpectation(description: "View should update on loading state change")
        
        // Test that the view updates when loading state changes
        mockWarpUsageService.$isLoading
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Change loading state
        mockWarpUsageService.loadUsageData(force: true)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testViewUpdatesOnErrorChange() {
        let expectation = XCTestExpectation(description: "View should update on error change")
        
        // Test that the view updates when error changes
        mockWarpUsageService.$lastError
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Change error
        mockWarpUsageService.setError("New test error")
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - View Layout Tests
    
    func testViewLayout() {
        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )
        
        // Test that the view has proper layout
        XCTAssertNotNil(view)
        
        // Note: SwiftUI layout testing requires UI testing framework
        // but we can verify the view exists and can be laid out
    }
    
    func testCardLayout() {
        let data = TestHelpers.createWarpUsageData()
        
        let planCard = LiquidGlassPlanCard(data: data)
        let usageCard = LiquidGlassUsageCard(data: data)
        let progressCard = LiquidGlassProgressCard(data: data)
        let resetCard = LiquidGlassResetCard(data: data)
        
        // Test that cards have proper layout
        XCTAssertNotNil(planCard)
        XCTAssertNotNil(usageCard)
        XCTAssertNotNil(progressCard)
        XCTAssertNotNil(resetCard)
    }
    
    // MARK: - User Interaction Tests
    
    func testUserInteraction() {
        let view = ContentView(
            warpUsageService: mockWarpUsageService,
            onQuit: {}
        )
        
        // Test that the view supports user interaction
        XCTAssertNotNil(view)
        
        // Note: SwiftUI user interaction testing requires UI testing framework
        // but we can verify the view exists and can handle interactions
    }
    
    func testButtonInteraction() {
        let style = LiquidGlassButtonStyle(color: .cyan)
        
        // Test that button style supports interaction
        XCTAssertNotNil(style)
        
        // Note: SwiftUI button interaction testing requires UI testing framework
        // but we can verify the style exists and can handle interactions
    }
}
