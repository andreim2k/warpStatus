import Foundation
import Combine
@testable import WarpStatus

// MARK: - Mock Warp Usage Service

/// Mock implementation of WarpUsageService for testing
/// Allows setting predefined data without file system dependencies
class MockWarpUsageService: ObservableObject {
    @Published var usageData: WarpUsageData?
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var lastUpdateTime: Date?

    init() {
        // Start with default mock data
        self.usageData = createDefaultWarpUsageData()
        self.lastUpdateTime = Date()
    }

    func loadUsageData(force: Bool = false) {
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isLoading = false
            self?.lastUpdateTime = Date()

            // If there's no error, keep current usage data
            if self?.lastError == nil {
                // Data remains as set
            }
        }
    }

    func setMockUsageData(
        requestsUsed: Int = 224,
        requestsLimit: Int = 2500,
        isUnlimited: Bool = false,
        subscriptionType: String = "Standard"
    ) {
        usageData = WarpUsageData(
            requestsUsed: requestsUsed,
            requestsLimit: requestsLimit,
            nextRefreshTime: Date().addingTimeInterval(86400),
            isUnlimited: isUnlimited,
            subscriptionType: subscriptionType
        )
        lastError = nil
        lastUpdateTime = Date()
    }

    func setError(_ error: String) {
        lastError = error
        usageData = nil
    }

    private func createDefaultWarpUsageData() -> WarpUsageData {
        return WarpUsageData(
            requestsUsed: 224,
            requestsLimit: 2500,
            nextRefreshTime: Date().addingTimeInterval(86400),
            isUnlimited: false,
            subscriptionType: "Standard"
        )
    }
}

// MARK: - Test Helpers

/// Helper functions for creating test data and services
class TestHelpers {
    /// Create a MockWarpUsageService with default data
    static func createMockWarpUsageService() -> MockWarpUsageService {
        let service = MockWarpUsageService()
        service.setMockUsageData()
        return service
    }

    /// Create a MockWarpUsageService with high usage
    static func createHighUsageWarpService() -> MockWarpUsageService {
        let service = MockWarpUsageService()
        service.setMockUsageData(
            requestsUsed: 2400,
            requestsLimit: 2500,
            subscriptionType: "Standard"
        )
        return service
    }

    /// Create a MockWarpUsageService with low usage
    static func createLowUsageWarpService() -> MockWarpUsageService {
        let service = MockWarpUsageService()
        service.setMockUsageData(
            requestsUsed: 50,
            requestsLimit: 2500,
            subscriptionType: "Standard"
        )
        return service
    }

    /// Create a MockWarpUsageService with unlimited plan
    static func createUnlimitedWarpService() -> MockWarpUsageService {
        let service = MockWarpUsageService()
        service.setMockUsageData(
            requestsUsed: 9999,
            requestsLimit: 0,
            isUnlimited: true,
            subscriptionType: "Pro"
        )
        return service
    }

    /// Create a MockWarpUsageService with an error
    static func createErrorWarpService() -> MockWarpUsageService {
        let service = MockWarpUsageService()
        service.setError("Mock error for testing")
        return service
    }

    /// Create WarpUsageData with customizable parameters
    static func createWarpUsageData(
        requestsUsed: Int = 224,
        requestsLimit: Int = 2500,
        nextRefreshTime: Date = Date().addingTimeInterval(86400),
        isUnlimited: Bool = false,
        subscriptionType: String = "Standard"
    ) -> WarpUsageData {
        return WarpUsageData(
            requestsUsed: requestsUsed,
            requestsLimit: requestsLimit,
            nextRefreshTime: nextRefreshTime,
            isUnlimited: isUnlimited,
            subscriptionType: subscriptionType
        )
    }
}

// MARK: - Test Constants

/// Common constants used across tests
struct TestConstants {
    // Timeouts
    static let defaultTimeout: TimeInterval = 1.0
    static let longTimeout: TimeInterval = 5.0
    static let shortTimeout: TimeInterval = 0.1

    // Mock usage values
    static let mockRequestsUsed: Int = 224
    static let mockRequestsLimit: Int = 2500
    static let mockUsagePercentage: Double = 0.0896 // 224/2500

    // Subscription types
    static let freePlan = "Free"
    static let basicPlan = "Basic"
    static let standardPlan = "Standard"
    static let proPlan = "Pro"

    // Test scenarios
    static let highUsagePercentage: Double = 0.95
    static let mediumUsagePercentage: Double = 0.75
    static let lowUsagePercentage: Double = 0.25

    // Date constants (in seconds)
    static let oneDayFromNow: TimeInterval = 86400
    static let oneWeekFromNow: TimeInterval = 604800
    static let oneMonthFromNow: TimeInterval = 2592000
}
