#!/usr/bin/swift

import Foundation

let plistPath = "\(NSHomeDirectory())/Library/Preferences/dev.warp.Warp-Stable.plist"

print("🔄 Monitoring Warp usage file for changes...")
print("📁 File: \(plistPath)")
print("⏰ Checking every second for updates...")
print("💡 Use Warp AI features to see real-time changes!")
print("")

var lastModificationDate: Date?
var lastUsageValue: Int?

func checkForChanges() {
    guard let attributes = try? FileManager.default.attributesOfItem(atPath: plistPath),
          let modificationDate = attributes[.modificationDate] as? Date else {
        print("❌ Could not read file attributes")
        return
    }
    
    // Check if file was modified
    let fileChanged = lastModificationDate == nil || modificationDate > lastModificationDate!
    lastModificationDate = modificationDate
    
    // Parse current usage
    if let plist = NSDictionary(contentsOfFile: plistPath),
       let aiRequestLimitString = plist["AIRequestLimitInfo"] as? String,
       let aiRequestData = aiRequestLimitString.data(using: .utf8),
       let aiRequestInfo = try? JSONSerialization.jsonObject(with: aiRequestData) as? [String: Any] {
        
        let currentUsage = aiRequestInfo["num_requests_used_since_refresh"] as? Int ?? 0
        let limit = aiRequestInfo["limit"] as? Int ?? 0
        
        if fileChanged || lastUsageValue != currentUsage {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            let changeType = fileChanged ? "📝 File modified" : "🔄 Usage updated"
            print("[\(timestamp)] \(changeType): \(currentUsage)/\(limit)")
            lastUsageValue = currentUsage
        }
    }
}

// Initial check
checkForChanges()

// Monitor every second
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    checkForChanges()
}

// Keep the script running
RunLoop.current.run()