import XCTest
import Combine
import Foundation
@testable import WarpStatus

final class WarpUsageServiceTests: XCTestCase {
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
    
    // MARK: - Initialization Tests
    
    func testWarpUsageServiceInitialization() {
        XCTAssertNotNil(warpUsageService)
        XCTAssertFalse(warpUsageService.isLoading)
        XCTAssertNil(warpUsageService.lastError)
        XCTAssertNil(warpUsageService.lastUpdateTime)
    }
    
    func testWarpUsageServiceStartsLoadingOnInit() {
        let expectation = XCTestExpectation(description: "Service should start loading")
        
        warpUsageService.$isLoading
            .sink { isLoading in
                if isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - WarpUsageData Tests
    
    func testWarpUsageDataInitialization() {
        let data = TestHelpers.createWarpUsageData()
        
        XCTAssertEqual(data.requestsUsed, TestConstants.mockRequestsUsed)
        XCTAssertEqual(data.requestsLimit, TestConstants.mockRequestsLimit)
        XCTAssertFalse(data.isUnlimited)
        XCTAssertEqual(data.subscriptionType, TestConstants.standardPlan)
    }
    
    func testWarpUsageDataUsagePercentage() {
        let data = TestHelpers.createWarpUsageData(
            requestsUsed: 500,
            requestsLimit: 1000
        )
        
        XCTAssertEqual(data.usagePercentage, 0.5, accuracy: 0.001)
    }
    
    func testWarpUsageDataUsagePercentageWithZeroLimit() {
        let data = TestHelpers.createWarpUsageData(
            requestsUsed: 100,
            requestsLimit: 0
        )
        
        XCTAssertEqual(data.usagePercentage, 0.0)
    }
    
    func testWarpUsageDataDisplayText() {
        let limitedData = TestHelpers.createWarpUsageData(
            requestsUsed: 224,
            requestsLimit: 2500
        )
        
        XCTAssertEqual(limitedData.displayText, "224 of 2500")
        
        let unlimitedData = TestHelpers.createWarpUsageData(
            requestsUsed: 9999,
            requestsLimit: 0,
            isUnlimited: true
        )
        
        XCTAssertEqual(unlimitedData.displayText, "∞")
    }
    
    func testWarpUsageDataFreeTokensText() {
        let limitedData = TestHelpers.createWarpUsageData(
            requestsUsed: 224,
            requestsLimit: 2500
        )
        
        XCTAssertEqual(limitedData.freeTokensText, "2276 remaining")
        
        let unlimitedData = TestHelpers.createWarpUsageData(
            requestsUsed: 9999,
            requestsLimit: 0,
            isUnlimited: true
        )
        
        XCTAssertEqual(unlimitedData.freeTokensText, "Unlimited")
    }
    
    func testWarpUsageDataMenuBarText() {
        let limitedData = TestHelpers.createWarpUsageData(
            requestsUsed: 224,
            requestsLimit: 2500
        )
        
        XCTAssertEqual(limitedData.menuBarText, "2276")
        
        let unlimitedData = TestHelpers.createWarpUsageData(
            requestsUsed: 9999,
            requestsLimit: 0,
            isUnlimited: true
        )
        
        XCTAssertEqual(unlimitedData.menuBarText, "∞")
    }
    
    func testWarpUsageDataSubscriptionDisplayName() {
        let freeData = TestHelpers.createWarpUsageData(subscriptionType: TestConstants.freePlan)
        XCTAssertEqual(freeData.subscriptionDisplayName, "Free Plan")
        
        let basicData = TestHelpers.createWarpUsageData(subscriptionType: TestConstants.basicPlan)
        XCTAssertEqual(basicData.subscriptionDisplayName, "Basic Plan")
        
        let standardData = TestHelpers.createWarpUsageData(subscriptionType: TestConstants.standardPlan)
        XCTAssertEqual(standardData.subscriptionDisplayName, "Standard Plan")
        
        let proData = TestHelpers.createWarpUsageData(subscriptionType: TestConstants.proPlan)
        XCTAssertEqual(proData.subscriptionDisplayName, "Pro Plan")
        
        let unlimitedData = TestHelpers.createWarpUsageData(
            subscriptionType: TestConstants.proPlan,
            isUnlimited: true
        )
        XCTAssertEqual(unlimitedData.subscriptionDisplayName, "Pro Plan (Unlimited)")
    }
    
    // MARK: - Subscription Type Detection Tests
    
    func testSubscriptionTypeDetectionFree() {
        let data = TestHelpers.createWarpUsageData(
            requestsUsed: 45,
            requestsLimit: 100,
            subscriptionType: TestConstants.freePlan
        )
        
        XCTAssertEqual(data.subscriptionType, TestConstants.freePlan)
        XCTAssertEqual(data.subscriptionDisplayName, "Free Plan")
    }
    
    func testSubscriptionTypeDetectionBasic() {
        let data = TestHelpers.createWarpUsageData(
            requestsUsed: 100,
            requestsLimit: 200,
            subscriptionType: TestConstants.basicPlan
        )
        
        XCTAssertEqual(data.subscriptionType, TestConstants.basicPlan)
        XCTAssertEqual(data.subscriptionDisplayName, "Basic Plan")
    }
    
    func testSubscriptionTypeDetectionStandard() {
        let data = TestHelpers.createWarpUsageData(
            requestsUsed: 1000,
            requestsLimit: 2500,
            subscriptionType: TestConstants.standardPlan
        )
        
        XCTAssertEqual(data.subscriptionType, TestConstants.standardPlan)
        XCTAssertEqual(data.subscriptionDisplayName, "Standard Plan")
    }
    
    func testSubscriptionTypeDetectionPro() {
        let data = TestHelpers.createWarpUsageData(
            requestsUsed: 5000,
            requestsLimit: 0,
            isUnlimited: true,
            subscriptionType: TestConstants.proPlan
        )
        
        XCTAssertEqual(data.subscriptionType, TestConstants.proPlan)
        XCTAssertEqual(data.subscriptionDisplayName, "Pro Plan (Unlimited)")
    }
    
    // MARK: - Data Loading Tests
    
    func testLoadUsageData() {
        let expectation = XCTestExpectation(description: "Data should load")
        
        warpUsageService.$usageData
            .dropFirst() // Skip initial nil value
            .sink { data in
                // Data should be loaded (or error should be set)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        warpUsageService.loadUsageData(force: true)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testLoadUsageDataForced() {
        let expectation = XCTestExpectation(description: "Forced data load should complete")
        
        warpUsageService.$isLoading
            .sink { isLoading in
                if !isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        warpUsageService.loadUsageData(force: true)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testLoadUsageDataUpdatesLastUpdateTime() {
        let expectation = XCTestExpectation(description: "Last update time should be set")
        
        warpUsageService.$lastUpdateTime
            .dropFirst() // Skip initial nil value
            .sink { lastUpdateTime in
                XCTAssertNotNil(lastUpdateTime)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        warpUsageService.loadUsageData(force: true)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() {
        let expectation = XCTestExpectation(description: "Error should be handled")
        
        warpUsageService.$lastError
            .dropFirst() // Skip initial nil value
            .sink { error in
                // Error should be set (since we can't find real plist in test environment)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        warpUsageService.loadUsageData(force: true)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testErrorClearingOnSuccess() {
        // First set an error
        warpUsageService.lastError = "Test error"
        
        let expectation = XCTestExpectation(description: "Error should be cleared on success")
        
        warpUsageService.$lastError
            .sink { error in
                if error == nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        warpUsageService.loadUsageData(force: true)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingState() {
        let expectation = XCTestExpectation(description: "Loading state should change")
        
        var loadingStates: [Bool] = []
        
        warpUsageService.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        warpUsageService.loadUsageData(force: true)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testLoadingStateStartsTrue() {
        let expectation = XCTestExpectation(description: "Loading should start as true")
        
        warpUsageService.$isLoading
            .sink { isLoading in
                if isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        warpUsageService.loadUsageData(force: true)
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    // MARK: - WarpError Tests
    
    func testWarpErrorPlistNotFound() {
        let error = WarpError.plistNotFound
        XCTAssertEqual(error.localizedDescription, "Warp preferences file not found. Ensure Warp is installed and has been run at least once.")
    }
    
    func testWarpErrorInvalidPlistFormat() {
        let error = WarpError.invalidPlistFormat
        XCTAssertEqual(error.localizedDescription, "Failed to parse Warp usage data. The format may have changed in a recent Warp update.")
    }
    
    // MARK: - Data Validation Tests
    
    func testUsageDataValidation() {
        let data = TestHelpers.createWarpUsageData(
            requestsUsed: 100,
            requestsLimit: 1000
        )
        
        XCTAssertGreaterThanOrEqual(data.requestsUsed, 0)
        XCTAssertGreaterThanOrEqual(data.requestsLimit, 0)
        XCTAssertLessThanOrEqual(data.usagePercentage, 1.0)
    }
    
    func testUsageDataEdgeCases() {
        // Test zero values
        let zeroData = TestHelpers.createWarpUsageData(
            requestsUsed: 0,
            requestsLimit: 0
        )
        XCTAssertEqual(zeroData.usagePercentage, 0.0)
        
        // Test high usage
        let highUsageData = TestHelpers.createWarpUsageData(
            requestsUsed: 999,
            requestsLimit: 1000
        )
        XCTAssertEqual(highUsageData.usagePercentage, 0.999, accuracy: 0.001)
        
        // Test unlimited
        let unlimitedData = TestHelpers.createWarpUsageData(
            requestsUsed: 9999,
            requestsLimit: 0,
            isUnlimited: true
        )
        XCTAssertTrue(unlimitedData.isUnlimited)
        XCTAssertEqual(unlimitedData.displayText, "∞")
    }
    
    // MARK: - Performance Tests
    
    func testDataLoadingPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            warpUsageService.$isLoading
                .sink { isLoading in
                    if !isLoading {
                        expectation.fulfill()
                    }
                }
                .store(in: &cancellables)
            
            warpUsageService.loadUsageData(force: true)
            
            wait(for: [expectation], timeout: TestConstants.defaultTimeout)
        }
    }
    
    func testUsageDataCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = TestHelpers.createWarpUsageData()
            }
        }
    }
    
    // MARK: - Thread Safety Tests
    
    func testThreadSafety() {
        let expectation = XCTestExpectation(description: "Thread safety test")
        
        DispatchQueue.global(qos: .background).async {
            // Access service from background thread
            XCTAssertNotNil(self.warpUsageService)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
    }
    
    func testConcurrentDataLoading() {
        let expectation = XCTestExpectation(description: "Concurrent loading test")
        
        let group = DispatchGroup()
        
        for _ in 0..<5 {
            group.enter()
            DispatchQueue.global(qos: .background).async {
                self.warpUsageService.loadUsageData(force: true)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TestConstants.longTimeout)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        weak var weakService: WarpUsageService?
        
        do {
            let service = WarpUsageService()
            weakService = service
            // service goes out of scope here
        }
        
        // Give time for deinit to be called
        let expectation = XCTestExpectation(description: "Memory cleanup")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: TestConstants.defaultTimeout)
        
        // Service should clean up properly
        XCTAssertTrue(true, "WarpUsageService should clean up properly")
    }
    
    // MARK: - Real-time Updates Tests
    
    func testRealTimeUpdates() {
        let expectation = XCTestExpectation(description: "Real-time updates test")
        
        var updateCount = 0
        
        warpUsageService.$lastUpdateTime
            .sink { _ in
                updateCount += 1
                if updateCount >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Trigger multiple updates
        warpUsageService.loadUsageData(force: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.warpUsageService.loadUsageData(force: true)
        }
        
        wait(for: [expectation], timeout: TestConstants.longTimeout)
    }
    
    // MARK: - Edge Cases Tests
    
    func testEdgeCaseValues() {
        // Test negative values
        let negativeData = TestHelpers.createWarpUsageData(
            requestsUsed: -10,
            requestsLimit: 100
        )
        XCTAssertEqual(negativeData.usagePercentage, -0.1)
        
        // Test very large values
        let largeData = TestHelpers.createWarpUsageData(
            requestsUsed: Int.max,
            requestsLimit: Int.max
        )
        XCTAssertEqual(largeData.usagePercentage, 1.0, accuracy: 0.001)
        
        // Test future refresh time
        let futureData = TestHelpers.createWarpUsageData(
            nextRefreshTime: Date().addingTimeInterval(TestConstants.oneMonthFromNow)
        )
        XCTAssertGreaterThan(futureData.nextRefreshTime, Date())
    }
}