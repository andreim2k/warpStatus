import SwiftUI
import ServiceManagement

/// Preferences window for user customization
struct PreferencesView: View {
    @AppStorage("refreshInterval") private var refreshInterval: Double = 1.0
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("showIconInMenuBar") private var showIconInMenuBar: Bool = true
    @AppStorage("compactDisplay") private var compactDisplay: Bool = false
    @AppStorage("autoStartOnLogin") private var autoStartOnLogin: Bool = false
    
    @State private var showingNotificationPermission = false
    @State private var showingResetConfirmation = false
    
    var body: some View {
        VStack(spacing: AppConfiguration.uiConstants.largeSpacing) {
            // Header
            headerSection
            
            // General Settings
            generalSettingsSection
            
            // Display Settings
            displaySettingsSection
            
            // Notification Settings
            notificationSettingsSection
            
            // Advanced Settings
            advancedSettingsSection
            
            Spacer()
            
            // Footer
            footerSection
        }
        .padding(AppConfiguration.uiConstants.windowPadding)
        .frame(width: AppConfiguration.uiConstants.preferencesWindowWidth, height: AppConfiguration.uiConstants.preferencesWindowHeight)
        .background(
            RoundedRectangle(cornerRadius: AppConfiguration.uiConstants.mediumCornerRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConfiguration.uiConstants.mediumCornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "gear.circle.fill")
                .font(.system(size: AppConfiguration.uiConstants.titleFontSize, weight: .semibold))
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading) {
                Text("WarpStatus Preferences")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Customize your Warp usage monitoring")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Refresh Interval")
                    Spacer()
                    Picker("Refresh Interval", selection: $refreshInterval) {
                        Text("0.5s").tag(0.5)
                        Text("1s").tag(1.0)
                        Text("2s").tag(2.0)
                        Text("5s").tag(5.0)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: AppConfiguration.uiConstants.buttonMinWidth)
                }
                
                Toggle("Auto-start on login", isOn: $autoStartOnLogin)
                    .onChange(of: autoStartOnLogin) { _, enabled in
                        toggleAutoStart(on: enabled)
                    }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.6))
        )
    }
    
    private var displaySettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Display")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(spacing: 8) {
                Toggle("Show icon in menu bar", isOn: $showIconInMenuBar)
                Toggle("Compact display mode", isOn: $compactDisplay)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.6))
        )
    }
    
    private var notificationSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(spacing: 8) {
                Toggle("Enable usage alerts", isOn: $enableNotifications)
                    .onChange(of: enableNotifications) { _, enabled in
                        if enabled {
                            showingNotificationPermission = true
                        }
                    }
                
                HStack {
                    Text("Usage thresholds:")
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Warning: 70%")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("Critical: 90%")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.6))
        )
        .alert("Enable Notifications", isPresented: $showingNotificationPermission) {
            Button("OK") {
                NotificationCenter.default.post(name: .requestNotificationPermission, object: nil)
            }
            Button("Cancel") {
                enableNotifications = false
            }
        } message: {
            Text("WarpStatus needs notification permission to alert you when you're approaching your usage limits.")
        }
    }
    
    private var advancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced")
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(spacing: 8) {
                Button("Reset to Defaults") {
                    showingResetConfirmation = true
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.blue)
                
                Text("This will reset all preferences to their default values.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.6))
        )
        .alert("Reset Preferences", isPresented: $showingResetConfirmation) {
            Button("Reset", role: .destructive) {
                resetToDefaults()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to reset all preferences to their default values? This action cannot be undone.")
        }
    }
    
    private var footerSection: some View {
        HStack {
            Text("WarpStatus v2.0")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("Made with ❤️ for Warp users")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private func toggleAutoStart(on: Bool) {
        // Note: This requires the app to be signed and notarized for production use
        // For development, this will show a permission dialog
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.warpstatus.app"
        
        if on {
            // Check if already enabled
            if !SMLoginItemSetEnabled(bundleIdentifier as CFString, true) {
                print("Failed to enable login item. User may have denied permission.")
            }
        } else {
            if !SMLoginItemSetEnabled(bundleIdentifier as CFString, false) {
                print("Failed to disable login item.")
            }
        }
    }
    
    private func resetToDefaults() {
        refreshInterval = 1.0
        enableNotifications = true
        showIconInMenuBar = true
        compactDisplay = false
        autoStartOnLogin = false
    }
}

// MARK: - Preferences View Window Controller

class PreferencesWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.title = "WarpStatus Preferences"
        window?.styleMask.remove(.resizable)
        window?.center()
        
        // Set up content view
        let preferencesView = PreferencesView()
        let hostingController = NSHostingController(rootView: preferencesView)
        contentViewController = hostingController
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let requestNotificationPermission = Notification.Name("RequestNotificationPermission")
}