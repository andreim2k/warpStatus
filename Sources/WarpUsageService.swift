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

class WarpUsageService: ObservableObject {
    @Published var usageData: WarpUsageData?
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var lastUpdateTime: Date?
    
    private var plistPath: String?
    private var fileMonitor: DispatchSourceFileSystemObject?

    init() {
        self.plistPath = findWarpPlistPath()
        if self.plistPath == nil {
            self.lastError = "Warp preferences file not found. Please ensure Warp is installed."
        }
        loadUsageData(force: true)
        setupFileMonitor()
    }

    deinit {
        fileMonitor?.cancel()
    }
    
    func loadUsageData(force: Bool = false) {
        isLoading = true
        // Don't reset error immediately, so the UI can show it until loading is complete
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let data = try self?.parseWarpPlist()
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.usageData = data
                    self?.lastUpdateTime = Date()
                    self?.lastError = nil // Clear error on success
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.lastError = error.localizedDescription
                }
            }
        }
    }
    
    private func findWarpPlistPath() -> String? {
        let fileManager = FileManager.default
        let preferencesDir = "\(NSHomeDirectory())/Library/Preferences/"

        // Potential plist file names
        let plistFileNames = [
            "dev.warp.Warp-Stable.plist",
            "dev.warp.Warp-Beta.plist",
            "dev.warp.Warp-Nightly.plist",
            "dev.warp.Warp.plist"
        ]

        for fileName in plistFileNames {
            let fullPath = preferencesDir + fileName
            if fileManager.fileExists(atPath: fullPath) {
                return fullPath
            }
        }

        return nil
    }

    private func setupFileMonitor() {
        guard let path = plistPath else { return }

        let fileURL = URL(fileURLWithPath: path)
        // O_EVTONLY is a Mach-specific flag that returns a file descriptor suitable for kqueue-based event notifications
        let fileDescriptor = open(fileURL.path, O_EVTONLY)

        guard fileDescriptor != -1 else {
            lastError = "Unable to monitor Warp preferences file for changes."
            return
        }

        fileMonitor = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .write, queue: .main)

        fileMonitor?.setEventHandler { [weak self] in
            // When a write event is detected, reload the data
            self?.loadUsageData(force: true)
        }
        
        fileMonitor?.setCancelHandler {
            close(fileDescriptor)
        }
        
        fileMonitor?.resume()
    }
    
    private func parseWarpPlist() throws -> WarpUsageData {
        guard let plistPath = plistPath, let plist = NSDictionary(contentsOfFile: plistPath) else {
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
            return "Warp preferences file not found. Ensure Warp is installed and has been run at least once."
        case .invalidPlistFormat:
            return "Failed to parse Warp usage data. The format may have changed in a recent Warp update."
        }
    }
}