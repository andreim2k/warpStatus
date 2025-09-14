import SwiftUI
import AppKit
import Combine

class MenuBarController: NSObject, ObservableObject {
    private var statusBarItem: NSStatusItem!
    private let warpUsageService = WarpUsageService()
    private var timer: Timer?
    
    override init() {
        super.init()
        setupMenuBar()
        setupTimer()
    }
    
    private func setupMenuBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem.button {
            button.title = "Loading..."
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        
        // Listen for usage data updates
        warpUsageService.$usageData.sink { [weak self] data in
            DispatchQueue.main.async {
                self?.updateStatusBarButton(with: data)
            }
        }
        .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func setupTimer() {
        // Refresh every second for real-time updates
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.warpUsageService.loadUsageData()
        }
    }
    
    private func updateStatusBarButton(with data: WarpUsageData?) {
        guard let button = statusBarItem.button else { return }
        
        if let data = data {
            // Create an attributed string with icon and text
            let attachment = NSTextAttachment()
            if let icon = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: nil) {
                icon.size = NSSize(width: 12, height: 12)
                attachment.image = icon
            }
            
            let attributedString = NSMutableAttributedString(attachment: attachment)
            attributedString.append(NSAttributedString(string: " \(data.displayText)"))
            
            // Apply styling
            attributedString.addAttribute(.font, value: NSFont.systemFont(ofSize: 12), range: NSRange(location: 0, length: attributedString.length))
            
            // Color code based on usage percentage
            let color: NSColor
            if data.isUnlimited {
                color = .systemGreen
            } else {
                let percentage = data.usagePercentage
                if percentage < 0.7 {
                    color = .systemGreen
                } else if percentage < 0.9 {
                    color = .systemOrange
                } else {
                    color = .systemRed
                }
            }
            
            attributedString.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: attributedString.length))
            
            button.attributedTitle = attributedString
        } else {
            button.title = "⚠️"
        }
    }
    
    @objc private func statusBarButtonClicked() {
        let menu = createMenu()
        statusBarItem.menu = menu
        statusBarItem.button?.performClick(nil)
    }
    
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        if let data = warpUsageService.usageData {
            // Usage information section
            let usageItem = NSMenuItem()
            usageItem.title = "Usage: \(data.displayText)"
            usageItem.isEnabled = false
            menu.addItem(usageItem)
            
            // Subscription type
            let subscriptionItem = NSMenuItem()
            subscriptionItem.title = "Plan: \(data.subscriptionDisplayName)"
            subscriptionItem.isEnabled = false
            menu.addItem(subscriptionItem)
            
            // Progress bar visualization
            if !data.isUnlimited {
                let progressItem = NSMenuItem()
                let percentage = Int(data.usagePercentage * 100)
                let progressBar = createProgressBar(percentage: data.usagePercentage)
                progressItem.title = "\(progressBar) \(percentage)%"
                progressItem.isEnabled = false
                menu.addItem(progressItem)
            }
            
            // Next refresh time
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            let refreshItem = NSMenuItem()
            refreshItem.title = "Resets: \(formatter.string(from: data.nextRefreshTime))"
            refreshItem.isEnabled = false
            menu.addItem(refreshItem)
            
            menu.addItem(NSMenuItem.separator())
            
            // Real-time update indicator
            let realtimeItem = NSMenuItem()
            realtimeItem.title = "🔄 Live Updates (1s refresh)"
            realtimeItem.isEnabled = false
            menu.addItem(realtimeItem)
            
            // Last update time
            if let lastUpdate = warpUsageService.lastUpdateTime {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .medium
                let lastUpdateItem = NSMenuItem()
                lastUpdateItem.title = "Last updated: \(timeFormatter.string(from: lastUpdate))"
                lastUpdateItem.isEnabled = false
                menu.addItem(lastUpdateItem)
            }
            
        } else if warpUsageService.isLoading {
            let loadingItem = NSMenuItem()
            loadingItem.title = "Loading..."
            loadingItem.isEnabled = false
            menu.addItem(loadingItem)
        } else if let error = warpUsageService.lastError {
            let errorItem = NSMenuItem()
            errorItem.title = "Error: \(error)"
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Refresh action
        let refreshItem = NSMenuItem()
        refreshItem.title = "Refresh"
        refreshItem.action = #selector(refreshData)
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit action
        let quitItem = NSMenuItem()
        quitItem.title = "Quit Warp Status"
        quitItem.action = #selector(quitApp)
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    private func createProgressBar(percentage: Double) -> String {
        let barLength = 10
        let filledLength = Int(percentage * Double(barLength))
        let filled = String(repeating: "█", count: filledLength)
        let empty = String(repeating: "░", count: barLength - filledLength)
        return "[\(filled)\(empty)]"
    }
    
    @objc private func refreshData() {
        warpUsageService.loadUsageData()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    deinit {
        timer?.invalidate()
    }
}

