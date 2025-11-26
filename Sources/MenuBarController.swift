import SwiftUI
import AppKit
import Combine

class MenuBarController: NSObject, ObservableObject {
    private var statusBarItem: NSStatusItem!
    private var popover: NSPopover!
    private let warpUsageService: WarpUsageService
    private let notificationService: NotificationService
    private var statusBarManager: StatusBarManaging?
    private var cancellables = Set<AnyCancellable>()
    private var eventMonitor: Any?
    private var timer: Timer?

    // MARK: - Dependency Injection Initializer
    
    /// Initialize with dependency injection for better testability
    /// - Parameters:
    ///   - warpUsageService: Service for accessing Warp usage data (defaults to real service)
    ///   - statusBarManager: Manager for status bar interactions (defaults to real manager)
    init(warpUsageService: WarpUsageService = WarpUsageService(), 
         statusBarManager: StatusBarManaging? = nil,
         notificationService: NotificationService = NotificationService()) {
        self.warpUsageService = warpUsageService
        self.notificationService = notificationService
        self.statusBarManager = statusBarManager
        super.init()
        
        setupPopover()
        setupMenuBar()
        setupTimer()
        setupNotificationMonitoring()

        // Listen for usage data updates
        warpUsageService.$usageData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
            self?.updateStatusBarButton(with: data)
            if let data = data {
                self?.notificationService.sendUsageAlert(usageData: data)
            }
        }
        .store(in: &cancellables)
    }

    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        timer?.invalidate()
    }

    private func setupPopover() {
        let contentView = ContentView(warpUsageService: warpUsageService, onQuit: {
            NSApplication.shared.terminate(nil)
        })

        popover = NSPopover()
        popover.contentSize = AppConfiguration.menuBarPopoverSize
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
            
            // Set up status bar manager for dependency injection
            statusBarManager = statusBarManager ?? StatusBarManager(statusItem: statusBarItem)
            
            // Use status bar manager to set up button
            statusBarManager?.setupButton(target: self, action: #selector(togglePopover))
        }
    }

    private func setupTimer() {
        // Refresh every second for real-time updates
        timer = Timer.scheduledTimer(withTimeInterval: AppConfiguration.refreshInterval, repeats: true) { [weak self] _ in
            self?.warpUsageService.loadUsageData(force: true)
        }
    }
    
    private func setupNotificationMonitoring() {
        // Monitor for notification permission requests
        notificationService.$isAuthorized
            .receive(on: DispatchQueue.main)
            .sink { authorized in
                // Could update UI to show notification status
                if authorized {
                    // Notifications enabled - setup completed automatically in NotificationService
                }
            }
            .store(in: &cancellables)
    }

    private func updateStatusBarButton(with data: WarpUsageData?) {
        guard let button = statusBarItem?.button else { return }
        
        if let data = data {
            // Use status bar manager for cleaner architecture
            statusBarManager?.setTitle(data.menuBarText, withIcon: true)
        } else {
            statusBarManager?.setTitle("⚠️", withIcon: false)
        }
    }
    
    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
            statusBarManager?.hidePopover()
        } else {
            if let button = statusBarItem?.button {
                warpUsageService.loadUsageData(force: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                statusBarManager?.showPopover()
                
                // Ensure the popover becomes key and visible
                DispatchQueue.main.async {
                    self.popover.contentViewController?.view.window?.makeKey()
                }
            }
        }
    }
    
    // MARK: - Testing Methods
    
    /// Test-only method to simulate status bar button click
    func simulateTogglePopover() {
        togglePopover()
    }
    
    /// Test-only method to get current popover state
    var isPopoverCurrentlyShown: Bool {
        return popover.isShown
    }
    
    /// Test-only method to get status bar manager
    var testStatusBarManager: StatusBarManaging? {
        return statusBarManager
    }
}