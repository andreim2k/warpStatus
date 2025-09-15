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
            if let resourcePath = Bundle.module.path(forResource: "menubar_icon", ofType: "png"),
               let icon = NSImage(contentsOfFile: resourcePath) {
                icon.size = NSSize(width: 16, height: 16)
                attachment.image = icon
                // Center align icon with text
                attachment.bounds = CGRect(x: 0, y: -4, width: 16, height: 16)
            } else if let icon = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: nil) {
                // Fallback to system icon if custom icon is not available
                icon.size = NSSize(width: 16, height: 16)
                attachment.image = icon
                attachment.bounds = CGRect(x: 0, y: -4, width: 16, height: 16)
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
        // Force refresh to ensure menu shows latest data
        warpUsageService.loadUsageData(force: true)
        let menu = createMenu()
        statusBarItem.menu = menu
        statusBarItem.button?.performClick(nil)
    }
    
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        if let data = warpUsageService.usageData {
            // Next refresh time
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd, yyyy 'at' h:mm a"
            formatter.locale = Locale(identifier: "en_US")
            let refreshItem = NSMenuItem()
            refreshItem.title = "Resets: \(formatter.string(from: data.nextRefreshTime))"
            refreshItem.isEnabled = false
            menu.addItem(refreshItem)
            
            menu.addItem(NSMenuItem.separator())
        }
        
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
        warpUsageService.loadUsageData(force: true)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    deinit {
        timer?.invalidate()
    }
}

