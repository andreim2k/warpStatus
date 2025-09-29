# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

WarpStatus is a macOS menu bar application that provides real-time monitoring of Warp Terminal AI usage. It reads from Warp's local preferences file to display current usage statistics, subscription type, and usage limits directly in the menu bar with color-coded indicators.

## Key Development Commands

### Running the Application
```bash
# Quick start (recommended)
./run.sh

# Manual run
swift run WarpStatus

# Launch pre-built app bundle
./launch_app.sh
```

### Building
```bash
# Debug build
swift build

# Release build  
swift build -c release

# Install executable to system
swift build -c release
cp .build/release/WarpStatus /usr/local/bin/
```

### Testing & Development
```bash
# Monitor real-time file changes during development
./test_realtime.swift

# Test real-time updates (see demo_realtime.md for full guide)
./run.sh  # Start app in one terminal
./test_realtime.swift  # Monitor changes in another
```

### Cleanup
```bash
# Uninstall app
./uninstall.sh

# Kill running instances
pkill -f WarpStatus
```

## Architecture Overview

### Core Components

**WarpUsageService** (`Sources/WarpUsageService.swift`)
- Central service for reading and parsing Warp's preference plist
- Implements smart file change detection using modification dates
- Provides ObservableObject pattern for reactive UI updates
- Handles subscription type detection based on usage limits and features
- Supports both forced refreshes and optimized polling

**MenuBarController** (`Sources/MenuBarController.swift`) 
- Manages NSStatusBarItem and menu interactions
- Implements 1-second polling timer for real-time updates
- Handles color-coded status display (green/orange/red based on usage)
- Creates dynamic menus with usage details and refresh options
- Uses Combine for reactive data binding

**ContentView** (`Sources/ContentView.swift`)
- SwiftUI interface for the full application window (not actively used in menu bar mode)
- Provides detailed usage visualization with progress bars
- Demonstrates the data model usage patterns

**AppDelegate** (`Sources/main.swift`)
- Entry point that configures the app as menu bar utility (.accessory policy)
- Instantiates MenuBarController to manage the menu bar presence

### Data Flow

1. **WarpUsageService** monitors `~/Library/Preferences/dev.warp.Warp-Stable.plist`
2. **File change detection** prevents unnecessary parsing via modification date comparison  
3. **JSON parsing** extracts AI request limits from embedded JSON strings in plist
4. **Usage calculation** determines percentage, subscription type, and refresh dates
5. **Reactive updates** trigger UI changes through ObservableObject publishers
6. **Menu bar display** shows real-time colored usage indicators

### Key Design Patterns

- **Reactive Programming**: Uses Combine and ObservableObject for data flow
- **Smart Polling**: File modification checks before expensive plist parsing
- **Error Handling**: Comprehensive error types with user-friendly messages
- **Menu Bar Integration**: NSStatusBarItem with custom attributed strings and icons
- **Resource Management**: Proper timer cleanup and memory management

### Subscription Detection Logic

The app intelligently determines Warp subscription types by analyzing:
- `is_unlimited` flag for Pro unlimited plans
- Voice request limits (999999+ indicates Pro)  
- Max codebase indices (40+ indicates Pro)
- Request limits (2500+ Standard, 150+ Basic, <150 Free)

### Real-time Updates

- 1-second polling interval for responsive updates
- File modification checking prevents unnecessary processing
- Immediate UI updates when Warp AI features are used
- Color-coded visual feedback for usage thresholds

## Important Files & Locations

- **Warp Preferences**: `~/Library/Preferences/dev.warp.Warp-Stable.plist`
- **Main Source**: `Sources/` directory contains all Swift files
- **Build Output**: `.build/release/WarpStatus` (executable)
- **Shell Scripts**: `run.sh`, `launch_app.sh`, `uninstall.sh` for common tasks

## Development Notes

### Platform Requirements
- macOS 14.0+ (specified in Package.swift)
- Swift 5.9+ for building
- Xcode project available but Swift Package Manager is primary build system

### Menu Bar App Patterns
- Uses NSApplication.setActivationPolicy(.accessory) to hide from dock
- Menu creation is dynamic based on current data state
- Attributed strings used for icon + text display in menu bar

### Performance Considerations  
- Smart file change detection prevents unnecessary plist parsing
- 1-second update interval balances responsiveness with resource usage
- Background queue processing for file I/O operations
- Proper cleanup of timers and observers in deinit