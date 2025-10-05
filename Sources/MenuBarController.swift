import SwiftUI
import AppKit
import Combine

class MenuBarController: NSObject, ObservableObject {
    private var statusBarItem: NSStatusItem!
    private var popover: NSPopover!
    private let warpUsageService = WarpUsageService()
    private var cancellables = Set<AnyCancellable>()
    private var eventMonitor: Any?

    override init() {
        super.init()

        setupPopover()
        setupMenuBar()

        // Listen for usage data updates
        warpUsageService.$usageData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
            self?.updateStatusBarButton(with: data)
        }
        .store(in: &cancellables)
    }
    
    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }

    private func setupPopover() {
        let contentView = ContentView(warpUsageService: warpUsageService, onQuit: {
            NSApplication.shared.terminate(nil)
        })

        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 420)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        // Add event monitor to close popover when clicking outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.popover.isShown == true {
                self?.popover.performClose(nil)
            }
        }
    }
    
    private func setupMenuBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem.button {
            button.title = "Loading..."
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    private func updateStatusBarButton(with data: WarpUsageData?) {
        guard let button = statusBarItem.button else { return }
        
        if let data = data {
            // Create an attributed string with theme-adaptive SF Symbol icon and text
            let attachment = NSTextAttachment()
            // Use only SF Symbol for clean black/white appearance
            if let icon = NSImage(systemSymbolName: "terminal", accessibilityDescription: nil) {
                // Clean outline terminal icon - professional macOS style
                icon.size = NSSize(width: 16, height: 16)
                icon.isTemplate = true  // Enable template rendering for theme adaptation
                attachment.image = icon
                attachment.bounds = CGRect(x: 0, y: -4, width: 16, height: 16)
            }
            
            let attributedString = NSMutableAttributedString(attachment: attachment)
            attributedString.append(NSAttributedString(string: " \(data.menuBarText)"))
            
            // Apply SF Mono font - same as SystemMonitor
            let monoFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
            attributedString.addAttribute(.font, value: monoFont, range: NSRange(location: 0, length: attributedString.length))
            
            // Use theme-adaptive colors (black/white) instead of colored indicators
            let themeColor = NSColor.controlTextColor  // Auto-adapts to light/dark theme
            attributedString.addAttribute(.foregroundColor, value: themeColor, range: NSRange(location: 0, length: attributedString.length))
            
            button.attributedTitle = attributedString
        } else {
            button.title = "⚠️"
        }
    }
    
    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusBarItem.button {
                warpUsageService.loadUsageData(force: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                
                // Ensure the popover becomes key and visible
                DispatchQueue.main.async {
                    self.popover.contentViewController?.view.window?.makeKey()
                }
            }
        }
    }
}