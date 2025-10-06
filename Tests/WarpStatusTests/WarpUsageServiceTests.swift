import XCTest
@testable import WarpStatus

class WarpUsageServiceTests: XCTestCase {
    var service: WarpUsageService!
    
    override func setUp() {
        super.setUp()
        service = WarpUsageService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Subscription Detection Tests
    
    func testProPlanDetection() {
        let plistData: [String: Any] = [
            "AIRequestLimitInfo": """
            {
                "num_requests_used_since_refresh": 150,
                "limit": 2500,
                "is_unlimited": true,
                "voice_request_limit": 999999,
                "max_codebase_indices": 50,
                "next_refresh_time": "2024-01-01T00:00:00.000Z"
            }
            """
        ]
        
        let mockPlist = NSDictionary(dictionary: plistData)
        let subscriptionType = service.determineSubscriptionType(
            plist: mockPlist,
            requestsLimit: 2500,
            isUnlimited: true
        )
        
        XCTAssertEqual(subscriptionType, "Pro")
    }
    
    func testStandardPlanDetection() {
        let plistData: [String: Any] = [
            "AIRequestLimitInfo": """
            {
                "num_requests_used_since_refresh": 500,
                "limit": 2500,
                "is_unlimited": false,
                "voice_request_limit": 100,
                "max_codebase_indices": 10,
                "next_refresh_time": "2024-01-01T00:00:00.000Z"
            }
            """
        ]
        
        let mockPlist = NSDictionary(dictionary: plistData)
        let subscriptionType = service.determineSubscriptionType(
            plist: mockPlist,
            requestsLimit: 2500,
            isUnlimited: false
        )
        
        XCTAssertEqual(subscriptionType, "Standard")
    }
    
    func testBasicPlanDetection() {
        let plistData: [String: Any] = [
            "AIRequestLimitInfo": """
            {
                "num_requests_used_since_refresh": 50,
                "limit": 200,
                "is_unlimited": false,
                "voice_request_limit": 50,
                "max_codebase_indices": 5,
                "next_refresh_time": "2024-01-01T00:00:00.000Z"
            }
            """
        ]
        
        let mockPlist = NSDictionary(dictionary: plistData)
        let subscriptionType = service.determineSubscriptionType(
            plist: mockPlist,
            requestsLimit: 200,
            isUnlimited: false
        )
        
        XCTAssertEqual(subscriptionType, "Basic")
    }
    
    func testFreePlanDetection() {
        let plistData: [String: Any] = [
            "AIRequestLimitInfo": """
            {
                "num_requests_used_since_refresh": 10,
                "limit": 100,
                "is_unlimited": false,
                "voice_request_limit": 10,
                "max_codebase_indices": 1,
                "next_refresh_time": "2024-01-01T00:00:00.000Z"
            }
            """
        ]
        
        let mockPlist = NSDictionary(dictionary: plistData)
        let subscriptionType = service.determineSubscriptionType(
            plist: mockPlist,
            requestsLimit: 100,
            isUnlimited: false
        )
        
        XCTAssertEqual(subscriptionType, "Free")
    }
    
    // MARK: - Data Parsing Tests
    
    func testWarpUsageDataCreation() {
        let usageData = WarpUsageData(
            requestsUsed: 150,
            requestsLimit: 2500,
            nextRefreshTime: Date(),
            isUnlimited: false,
            subscriptionType: "Pro"
        )
        
        XCTAssertEqual(usageData.requestsUsed, 150)
        XCTAssertEqual(usageData.requestsLimit, 2500)
        XCTAssertFalse(usageData.isUnlimited)
        XCTAssertEqual(usageData.subscriptionType, "Pro")
        XCTAssertEqual(usageData.usagePercentage, 0.06, accuracy: 0.01)
    }
    
    func testUnlimitedUsageData() {
        let usageData = WarpUsageData(
            requestsUsed: 999999,
            requestsLimit: 0,
            nextRefreshTime: Date(),
            isUnlimited: true,
            subscriptionType: "Pro"
        )
        
        XCTAssertTrue(usageData.isUnlimited)
        XCTAssertEqual(usageData.usagePercentage, 0.0)
        XCTAssertEqual(usageData.displayText, "∞")
        XCTAssertEqual(usageData.freeTokensText, "Unlimited")
        XCTAssertEqual(usageData.menuBarText, "∞")
    }
    
    func testUsagePercentageCalculation() {
        let usageData = WarpUsageData(
            requestsUsed: 750,
            requestsLimit: 2500,
            nextRefreshTime: Date(),
            isUnlimited: false,
            subscriptionType: "Standard"
        )
        
        XCTAssertEqual(usageData.usagePercentage, 0.3, accuracy: 0.01)
    }
    
    // MARK: - Error Handling Tests
    
    func testPlistNotFoundError() {
        let error = WarpError.plistNotFound
        XCTAssertEqual(error.localizedDescription, "Warp preferences file not found. Ensure Warp is installed and has been run at least once.")
    }
    
    func testInvalidPlistFormatError() {
        let error = WarpError.invalidPlistFormat
        XCTAssertEqual(error.localizedDescription, "Failed to parse Warp usage data. The format may have changed in a recent Warp update.")
    }
}

// MARK: - Test Helpers

extension WarpUsageService {
    // Expose private method for testing
    func determineSubscriptionType(plist: NSDictionary, requestsLimit: Int, isUnlimited: Bool) -> String {
        if isUnlimited {
            return "Pro"
        }
        
        // Check for high voice limits (Pro plan indicator)
        if let aiRequestLimitString = plist["AIRequestLimitInfo"] as? String,
           let aiRequestData = aiRequestLimitString.data(using: .utf8),
           let aiRequestInfo = try? JSONSerialization.jsonObject(with: aiRequestData) as? [String: Any] {
            
            let voiceRequestLimit = aiRequestInfo["voice_request_limit"] as? Int ?? 0
            let maxCodebaseIndices = aiRequestInfo["max_codebase_indices"] as? Int ?? 0
            
            // Pro plan has high voice limits and more codebase indices
            if voiceRequestLimit >= 999999 && maxCodebaseIndices >= 40 && requestsLimit >= 2500 {
                return "Pro"
            }
        }
        
        // Standard plan detection
        if requestsLimit >= 2500 {
            return "Standard"
        } else if requestsLimit > 150 {
            return "Basic"
        } else {
            return "Free"
        }
    }
}
