import Foundation
import AppKit

/// Protocol for status bar management to enable dependency injection and testing
protocol StatusBarManaging: AnyObject {
    func setTitle(_ title: String, withIcon: Bool)
    func showPopover()
    func hidePopover()
    var isPopoverShown: Bool { get set }
    func setupButton(target: AnyObject, action: Selector)
}

/// Default implementation for NSStatusBar interactions
class StatusBarManager: StatusBarManaging {
    private weak var statusItem: NSStatusItem?
    private var _isPopoverShown: Bool = false
    
    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
    }
    
    func setTitle(_ title: String, withIcon: Bool = false) {
        guard let button = statusItem?.button else { return }
        
        if withIcon {
            // Create attributed string with icon
            let attachment = NSTextAttachment()
            if let icon = NSImage(systemSymbolName: "terminal", accessibilityDescription: nil) {
                icon.size = NSSize(width: AppConfiguration.uiConstants.statusBarIconSize, height: AppConfiguration.uiConstants.statusBarIconSize)
                icon.isTemplate = true
                attachment.image = icon
                attachment.bounds = CGRect(x: 0, y: -4, width: AppConfiguration.uiConstants.statusBarIconSize, height: AppConfiguration.uiConstants.statusBarIconSize)
            }
            
            let attributedString = NSMutableAttributedString(attachment: attachment)
            attributedString.append(NSAttributedString(string: " \(title)"))
            
            let monoFont = NSFont.monospacedSystemFont(ofSize: AppConfiguration.uiConstants.smallFontSize, weight: .medium)
            attributedString.addAttribute(.font, value: monoFont, range: NSRange(location: 0, length: attributedString.length))
            
            let themeColor = NSColor.controlTextColor
            attributedString.addAttribute(.foregroundColor, value: themeColor, range: NSRange(location: 0, length: attributedString.length))
            
            button.attributedTitle = attributedString
        } else {
            button.title = title
        }
    }
    
    func showPopover() {
        _isPopoverShown = true
    }
    
    func hidePopover() {
        _isPopoverShown = false
    }
    
    var isPopoverShown: Bool {
        get { return _isPopoverShown }
        set { _isPopoverShown = newValue }
    }
    
    func setupButton(target: AnyObject, action: Selector) {
        guard let button = statusItem?.button else { return }
        button.target = target
        button.action = action
    }
}