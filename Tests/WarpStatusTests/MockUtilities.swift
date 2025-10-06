import Foundation
import Combine
@testable import WarpStatus

// MARK: - Mock Warp Usage Data
class MockWarpUsageData: ObservableObject {
    @Published var requestsUsed: Int = 0
    @Published var requestsLimit: Int = 0
    @Published var nextRefreshTime: Date = Date()
    @Published var isUnlimited: Bool = false
    @Published var subscriptionType: String = "Free"
    
    // Mock data for testing
    func setMockData(
        requestsUsed: Int = 224,
        requestsLimit: Int = 2500,
        nextRefreshTime: Date = Date().addingTimeInterval(86400), // 24 hours from now
        isUnlimited: Bool = false,
        subscriptionType: String = "Standard"
    ) {
        self.requestsUsed = requestsUsed
        self.requestsLimit = requestsLimit
        self.nextRefreshTime = nextRefreshTime
        self.isUnlimited = isUnlimited
        self.subscriptionType = subscriptionType
    }
    
    // Computed properties for testing
    var usagePercentage: Double {
        guard requestsLimit > 0 else { return 0 }
        return Double(requestsUsed) / Double(requestsLimit)
    }
    
    var displayText: String {
        if isUnlimited {
            return "∞"
        } else {
            return "\(requestsUsed) of \(requestsLimit)"
        }
    }
    
    var freeTokensText: String {
        if isUnlimited {
            return "Unlimited"
        } else {
            let freeTokens = requestsLimit - requestsUsed
            return "\(freeTokens) remaining"
        }
    }
    
    var menuBarText: String {
        if isUnlimited {
            return "∞"
        } else {
            let freeTokens = requestsLimit - requestsUsed
            return "\(freeTokens)"
        }
    }
    
    var subscriptionDisplayName: String {
        if isUnlimited {
            return "Pro Plan (Unlimited)"
        } else if subscriptionType == "Pro" {
            return "Pro Plan"
        } else if subscriptionType == "Standard" {
            return "Standard Plan"
        } else if subscriptionType == "Basic" {
            return "Basic Plan"
        } else {
            return "Free Plan"
        }
    }
}

// MARK: - Mock Warp Usage Service
class MockWarpUsageService: ObservableObject {
    @Published var usageData: WarpUsageData?
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var lastUpdateTime: Date?
    
    private var mockData: MockWarpUsageData
    
    init() {
        self.mockData = MockWarpUsageData()
        self.mockData.setMockData()
        self.usageData = createWarpUsageData()
    }
    
    func loadUsageData(force: Bool = false) {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isLoading = false
            self?.usageData = self?.createWarpUsageData()
            self?.lastUpdateTime = Date()
            self?.lastError = nil
        }
    }
    
    func setMockUsageData(
        requestsUsed: Int = 224,
        requestsLimit: Int = 2500,
        isUnlimited: Bool = false,
        subscriptionType: String = "Standard"
    ) {
        mockData.setMockData(
            requestsUsed: requestsUsed,
            requestsLimit: requestsLimit,
            isUnlimited: isUnlimited,
            subscriptionType: subscriptionType
        )
        usageData = createWarpUsageData()
    }
    
    func setError(_ error: String) {
        lastError = error
        usageData = nil
    }
    
    private func createWarpUsageData() -> WarpUsageData {
        return WarpUsageData(
            requestsUsed: mockData.requestsUsed,
            requestsLimit: mockData.requestsLimit,
            nextRefreshTime: mockData.nextRefreshTime,
            isUnlimited: mockData.isUnlimited,
            subscriptionType: mockData.subscriptionType
        )
    }
}

// MARK: - Test Helpers
class TestHelpers {
    static func waitForAsyncOperation(timeout: TimeInterval = 1.0) async {
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
    }
    
    static func createMockWarpUsageService() -> MockWarpUsageService {
        let service = MockWarpUsageService()
        service.setMockUsageData()
        return service
    }
    
    static func createHighUsageWarpService() -> MockWarpUsageService {
        let service = MockWarpUsageService()
        service.setMockUsageData(
            requestsUsed: 2400,
            requestsLimit: 2500,
            subscriptionType: "Standard"
        )
        return service
    }
    
    static func createLowUsageWarpService() -> MockWarpUsageService {
        let service = MockWarpUsageService()
        service.setMockUsageData(
            requestsUsed: 50,
            requestsLimit: 2500,
            subscriptionType: "Standard"
        )
        return service
    }
    
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
    
    static func createErrorWarpService() -> MockWarpUsageService {
        let service = MockWarpUsageService()
        service.setError("Mock error for testing")
        return service
    }
    
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

// MARK: - Test Expectations
extension XCTestCase {
    func expectAsync<T>(
        _ expression: @autoclosure () async throws -> T,
        timeout: TimeInterval = 1.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                return try await expression()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TestError.timeout
            }
            
            guard let result = try await group.next() else {
                throw TestError.timeout
            }
            
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Test Errors
enum TestError: Error {
    case timeout
    case mockDataNotSet
    case invalidUsageValue
    case subscriptionTypeNotFound
}

// MARK: - Test Constants
struct TestConstants {
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
    
    // Date constants
    static let oneDayFromNow: TimeInterval = 86400
    static let oneWeekFromNow: TimeInterval = 604800
    static let oneMonthFromNow: TimeInterval = 2592000
}

// MARK: - Mock Plist Data
struct MockPlistData {
    static let standardPlanPlist: [String: Any] = [
        "AIRequestLimitInfo": """
        {
            "num_requests_used_since_refresh": 224,
            "limit": 2500,
            "is_unlimited": false,
            "next_refresh_time": "2024-01-15T12:00:00.000Z",
            "voice_request_limit": 100,
            "max_codebase_indices": 10
        }
        """
    ]
    
    static let proPlanPlist: [String: Any] = [
        "AIRequestLimitInfo": """
        {
            "num_requests_used_since_refresh": 1500,
            "limit": 0,
            "is_unlimited": true,
            "next_refresh_time": "2024-01-15T12:00:00.000Z",
            "voice_request_limit": 999999,
            "max_codebase_indices": 50
        }
        """
    ]
    
    static let freePlanPlist: [String: Any] = [
        "AIRequestLimitInfo": """
        {
            "num_requests_used_since_refresh": 45,
            "limit": 100,
            "is_unlimited": false,
            "next_refresh_time": "2024-01-15T12:00:00.000Z",
            "voice_request_limit": 10,
            "max_codebase_indices": 1
        }
        """
    ]
    
    static let invalidPlist: [String: Any] = [
        "InvalidKey": "InvalidValue"
    ]
}

// MARK: - Mock File System
class MockFileSystem {
    static var mockPlistPath: String?
    static var mockFileExists: Bool = true
    static var mockFileModificationDate: Date = Date()
    
    static func reset() {
        mockPlistPath = nil
        mockFileExists = true
        mockFileModificationDate = Date()
    }
    
    static func setMockPlistPath(_ path: String) {
        mockPlistPath = path
    }
    
    static func setFileExists(_ exists: Bool) {
        mockFileExists = exists
    }
    
    static func setFileModificationDate(_ date: Date) {
        mockFileModificationDate = date
    }
}
