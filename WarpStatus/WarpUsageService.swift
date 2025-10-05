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
            let formatter = NumberFormatter()
            formatter.groupingSeparator = ""
            formatter.numberStyle = .none
            let usedStr = formatter.string(from: NSNumber(value: requestsUsed)) ?? "\(requestsUsed)"
            let limitStr = formatter.string(from: NSNumber(value: requestsLimit)) ?? "\(requestsLimit)"
            return "\(usedStr)/\(limitStr)"
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

class WarpUsageService: ObservableObject {
    @Published var usageData: WarpUsageData?
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var lastUpdateTime: Date?
    
    private let plistPath = "\(NSHomeDirectory())/Library/Preferences/dev.warp.Warp-Stable.plist"
    private var lastModificationDate: Date?
    
    init() {
        loadUsageData()
    }
    
    func loadUsageData() {
        loadUsageData(force: false)
    }
    
    func loadUsageData(force: Bool = false) {
        // Check if file has been modified before parsing (unless forced)
        if !force {
            guard hasFileChanged() else {
                return // No changes, skip update
            }
        }
        
        isLoading = true
        lastError = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let data = try self?.parseWarpPlist()
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.usageData = data
                    self?.lastUpdateTime = Date()
                    if force {
                        // Update modification date to reflect forced refresh
                        _ = self?.hasFileChanged()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.lastError = error.localizedDescription
                }
            }
        }
    }
    
    private func hasFileChanged() -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: plistPath),
              let modificationDate = attributes[.modificationDate] as? Date else {
            return true // If we can't get modification date, assume it changed
        }
        
        if lastModificationDate == nil || modificationDate > lastModificationDate! {
            lastModificationDate = modificationDate
            return true
        }
        
        return false
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
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            refreshDate = formatter.date(from: refreshTimeString) ?? Date()
        }
        
        // Determine subscription type based on limits and features
        let subscriptionType = determineSubscriptionType(plist: plist, requestsLimit: requestsLimit, isUnlimited: isUnlimited)
        
        return WarpUsageData(
            requestsUsed: requestsUsed,
            requestsLimit: requestsLimit,
            nextRefreshTime: refreshDate,
            isUnlimited: isUnlimited,
            subscriptionType: subscriptionType
        )
    }
    
    private func determineSubscriptionType(plist: NSDictionary, requestsLimit: Int, isUnlimited: Bool) -> String {
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