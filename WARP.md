# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

WarpStatus is a macOS menu bar application that monitors Warp Terminal's AI usage in real-time. The app displays usage statistics (e.g., "224/2500") directly in the menu bar with color-coded status indicators and provides detailed information through a dropdown menu.

## Development Commands

### Building and Running

**Quick development (recommended)**:
```bash
./run.sh
```

**Manual Swift Package Manager build**:
```bash
swift build -c release
swift run WarpStatus
```

**For app bundle testing**:
```bash
./launch_app.sh  # Launches WarpStatus.app if built
```

### Testing Real-time Functionality

```bash
./test_realtime.swift  # Monitor file changes and usage updates
```

**Testing workflow**: Run the monitor script, then use Warp AI features (ask questions, use Agent Mode) to observe real-time updates in both the monitor output and menu bar.

### Cleanup

```bash
./uninstall.sh  # Kills running processes and removes app bundle
```

## Architecture Overview

### Dual Build Structure
The project supports both Swift Package Manager and Xcode builds:
- `Sources/` - Swift Package Manager source files
- `WarpStatus/` - Xcode project source files (mostly identical)
- Both structures exist for build flexibility

### Core Components

**main.swift / WarpStatusApp.swift**
- App entry point and delegate setup
- Configures app as menu bar utility (`.accessory` activation policy)
- No dock icon, menu bar only

**MenuBarController.swift** 
- Manages NSStatusItem in menu bar
- Handles UI updates with real-time color coding:
  - Green: < 70% usage
  - Orange: 70-90% usage  
  - Red: > 90% usage
- Creates contextual menu with usage details, progress bar, refresh actions
- Updates every 1 second via Timer

**WarpUsageService.swift**
- Core data service using `@Published` properties for reactive updates
- Parses Warp's preference file: `~/Library/Preferences/dev.warp.Warp-Stable.plist`
- Extracts JSON from `AIRequestLimitInfo` or `AIAssistantRequestLimitInfo` keys
- Smart file change detection to avoid unnecessary parsing
- Subscription type detection based on limits and features

### Data Flow Architecture

1. **Timer-based Updates**: 1-second interval timer in MenuBarController
2. **File Change Detection**: WarpUsageService checks modification date before parsing
3. **Reactive UI**: Combine publishers automatically update menu bar when data changes
4. **Background Parsing**: Heavy plist operations happen on background queue
5. **Main Thread Updates**: UI updates dispatched to main thread

### Key Data Structures

**WarpUsageData**:
- `requestsUsed/requestsLimit`: Core usage metrics
- `isUnlimited`: Boolean for unlimited plans  
- `usagePercentage`: Computed property for progress bars
- `subscriptionType`: Detected plan type (Free, Standard, Pro)
- `nextRefreshTime`: When usage resets

## Critical Implementation Details

### Warp Preference File Structure
The app reads from Warp's plist file and parses embedded JSON strings. Key fields:
- `AIRequestLimitInfo` (primary) or `AIAssistantRequestLimitInfo` (fallback)
- JSON contains: `num_requests_used_since_refresh`, `limit`, `is_unlimited`, `next_refresh_time`

### Performance Optimizations
- **Smart Caching**: Only parses plist when file modification date changes
- **Efficient File Monitoring**: Uses FileManager attributes instead of file watchers
- **Background Processing**: Heavy parsing operations on background queue
- **Minimal UI Updates**: Only updates when actual data changes

### Subscription Detection Logic
The service determines plan types based on:
- `is_unlimited` flag for Pro unlimited
- Request limits: 2500+ (Pro/Standard), 150+ (Basic), <150 (Free)
- Voice request limits and codebase indices for Pro detection

### Menu Bar UI Patterns
- **NSStatusItem** with variable length for dynamic text
- **NSTextAttachment** for terminal icon alongside text
- **Color-coded NSAttributedString** for status indication
- **Progress bar visualization** using Unicode block characters (█░)

## Testing Approach

### Real-time Testing
Use `test_realtime.swift` to monitor file changes alongside the running app. This script demonstrates the file monitoring pattern and helps verify real-time updates work correctly.

### Manual Testing Scenarios
1. Start app → verify menu bar appearance
2. Use Warp AI features → verify instant counter updates
3. Click menu bar → verify detailed info display
4. Test near usage limits → verify color changes
5. Test with different Warp subscription types

## Build Requirements

- macOS 14.0+ (specified in Package.swift)
- Swift 5.9+
- Warp Terminal installed with AI usage history
- Access to `~/Library/Preferences/dev.warp.Warp-Stable.plist`

## Troubleshooting Context

**"Warp preferences file not found"**: User needs to use Warp AI features at least once to generate the plist file.

**"Unable to parse Warp usage data"**: Usually indicates Warp version compatibility issues or corrupted plist data.

**No menu bar icon**: App runs as accessory (no dock icon), look specifically in menu bar for terminal icon.