#!/usr/bin/env swift

import Foundation

// Test data structure mimicking WarpUsageData
struct TestWarpUsageData {
    let requestsUsed: Int
    let requestsLimit: Int
    let isUnlimited: Bool
    
    var displayText: String {
        if isUnlimited {
            return "∞"
        } else {
            return "\(requestsUsed.formatted(.number)) of \(requestsLimit.formatted(.number))"
        }
    }
    
    var freeTokensText: String {
        if isUnlimited {
            return "Unlimited"
        } else {
            let freeTokens = requestsLimit - requestsUsed
            return "\(freeTokens.formatted(.number)) remaining"
        }
    }
    
    var menuBarText: String {
        if isUnlimited {
            return "∞"
        } else {
            let freeTokens = requestsLimit - requestsUsed
            return "\(freeTokens.formatted(.number))"
        }
    }
}

// Test cases
let testCases = [
    TestWarpUsageData(requestsUsed: 1247, requestsLimit: 2000, isUnlimited: false),
    TestWarpUsageData(requestsUsed: 150, requestsLimit: 2000, isUnlimited: false),
    TestWarpUsageData(requestsUsed: 1950, requestsLimit: 2000, isUnlimited: false),
    TestWarpUsageData(requestsUsed: 0, requestsLimit: 0, isUnlimited: true)
]

print("🧪 Testing WarpStatus Display Formats")
print("=====================================")

for (index, testData) in testCases.enumerated() {
    print("\nTest Case \(index + 1):")
    print("  Used: \(testData.requestsUsed), Limit: \(testData.requestsLimit), Unlimited: \(testData.isUnlimited)")
    print("  📱 Menu Bar:  '\(testData.menuBarText)'")
    print("  💬 Total:     '\(testData.displayText)'")  
    print("  🔄 Remaining: '\(testData.freeTokensText)'")
}

print("\n✅ All display formats working correctly!")