import Foundation

struct WarpUsageData {
    let requestsUsed: Int
    let requestsLimit: Int
    let nextRefreshTime: Date
    let isUnlimited: Bool
    let subscriptionType: String
    
    var usagePercentage: Double {
        guard requestsLimit > 0 else { return 0 }
        return Double(requestsUsed) / Double(requestsLimit)
    }
    
    var displayText: String {
        if isUnlimited {
            return "∞/∞ (Unlimited)"
        } else {
            return "\(requestsUsed)/\(requestsLimit)"
        }
    }
    
    var subscriptionDisplayName: String {
        if isUnlimited {
            return "Pro Plan (Unlimited)"
        } else if subscriptionType == "Pro" {
            return "Pro Plan"
        } else if subscriptionType == "Standard" {
            return "Standard Plan"
        } else {
            return "Free Plan"
        }
    }
}

class WarpUsageService: ObservableObject {
    @Published var usageData: WarpUsageData?
    @Published var isLoading = false
    @Published var lastError: String?
    
    private let plistPath = "\(NSHomeDirectory())/Library/Preferences/dev.warp.Warp-Stable.plist"
    
    init() {
        loadUsageData()
    }
    
    func loadUsageData() {
        isLoading = true
        lastError = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let data = try self?.parseWarpPlist()
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.usageData = data
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.lastError = error.localizedDescription
                }
            }
        }
    }
    
    private func parseWarpPlist() throws -> WarpUsageData {
        guard let plist = NSDictionary(contentsOfFile: plistPath) else {
            throw WarpError.plistNotFound
        }
        
        // Try to get AI request limit info first, fall back to AI assistant if not available
        var limitInfoString = plist["AIRequestLimitInfo"] as? String
        if limitInfoString == nil {
            limitInfoString = plist["AIAssistantRequestLimitInfo"] as? String
        }
        
        guard let limitInfoString = limitInfoString,
              let limitInfoData = limitInfoString.data(using: .utf8),
              let limitInfo = try JSONSerialization.jsonObject(with: limitInfoData) as? [String: Any] else {
            throw WarpError.invalidPlistFormat
        }
        
        let requestsUsed = limitInfo["num_requests_used_since_refresh"] as? Int ?? 0
        let requestsLimit = limitInfo["limit"] as? Int ?? 0
        let isUnlimited = limitInfo["is_unlimited"] as? Bool ?? false
        
        var refreshDate = Date()
        if let refreshTimeString = limitInfo["next_refresh_time"] as? String {
            let formatter = ISO8601DateFormatter()
            refreshDate = formatter.date(from: refreshTimeString) ?? Date()
        }
        
        // Determine subscription type based on limits and features
        let subscriptionType: String
        if isUnlimited {
            subscriptionType = "Pro"
        } else if requestsLimit >= 2500 {
            // Check for premium model access to distinguish between plans
            subscriptionType = "Pro"
        } else if requestsLimit > 150 {
            subscriptionType = "Standard"
        } else {
            subscriptionType = "Free"
        }
        
        return WarpUsageData(
            requestsUsed: requestsUsed,
            requestsLimit: requestsLimit,
            nextRefreshTime: refreshDate,
            isUnlimited: isUnlimited,
            subscriptionType: subscriptionType
        )
    }
}

enum WarpError: Error, LocalizedError {
    case plistNotFound
    case invalidPlistFormat
    
    var errorDescription: String? {
        switch self {
        case .plistNotFound:
            return "Warp preferences file not found"
        case .invalidPlistFormat:
            return "Unable to parse Warp usage data"
        }
    }
}