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
            let truncatedText = freeTokens > 999 ? "\(freeTokens/1000)k" : "\(freeTokens)"
            return truncatedText.count > AppConfiguration.maxMenuBarTextLength ? 
                   "..." + String(truncatedText.suffix(AppConfiguration.maxMenuBarTextLength - 3)) : 
                   truncatedText
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
    
    var usageStatus: UsageStatus {
        if isUnlimited { return .unlimited }
        
        let percentage = usagePercentage
        if percentage >= AppConfiguration.notificationThresholds.criticalPercentage {
            return .critical
        } else if percentage >= AppConfiguration.notificationThresholds.warningPercentage {
            return .warning
        } else {
            return .healthy
        }
    }
}

enum UsageStatus {
    case healthy
    case warning
    case critical
    case unlimited
    
    var color: String {
        switch self {
        case .healthy: return AppConfiguration.usageColors.healthy
        case .warning: return AppConfiguration.usageColors.warning
        case .critical: return AppConfiguration.usageColors.critical
        case .unlimited: return AppConfiguration.usageColors.unlimited
        }
    }
}

class WarpUsageService: ObservableObject {
    @Published var usageData: WarpUsageData?
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var lastUpdateTime: Date?
    @Published var retryCount = 0
    
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
        retryCount = 0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.performDataLoadWithRetry(force: force)
        }
    }
    
    private func performDataLoadWithRetry(force: Bool, attempt: Int = 1) {
        guard attempt <= AppConfiguration.retryAttempts else {
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                self?.retryCount = 0
                self?.lastError = "Failed to load data after \(AppConfiguration.retryAttempts) attempts. Please check your Warp installation."
            }
            return
        }
        
        do {
            // Use self directly - this is safe since we're in the method context
            let data = try self.parseWarpPlist()
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                self?.usageData = data
                self?.lastUpdateTime = Date()
                self?.lastError = nil
                self?.retryCount = 0
            }
        } catch {
            if attempt < AppConfiguration.retryAttempts {
                // Exponential backoff: 1s, 2s, 4s...
                let delay = AppConfiguration.retryDelay * Double(pow(2.0, Double(attempt - 1)))
                DispatchQueue.main.async { [weak self] in
                    self?.retryCount = attempt
                }
                
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.performDataLoadWithRetry(force: force, attempt: attempt + 1)
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    self?.lastError = error.localizedDescription
                    self?.retryCount = 0
                }
            }
        }
    }
    
    private func findWarpPlistPath() -> String? {
        let fileManager = FileManager.default

        for fileName in AppConfiguration.supportedPlistNames {
            let fullPath = AppConfiguration.preferencesDirectory + fileName
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
            let errorCode = errno
            lastError = "Unable to monitor Warp preferences file for changes (Error code: \(errorCode))."
            return
        }

        do {
            fileMonitor = try DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .write, queue: .main)
            
            fileMonitor?.setEventHandler { [weak self] in
                // When a write event is detected, reload the data
                self?.loadUsageData(force: true)
            }
            
            fileMonitor?.setCancelHandler {
                close(fileDescriptor)
            }
            
            fileMonitor?.resume()
        } catch {
            close(fileDescriptor)
            lastError = "Failed to create file monitor for Warp preferences: \(error.localizedDescription)"
        }
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