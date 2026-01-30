# CLAUDE.md — WarpStatus

## What is this?

A macOS menu bar utility (Swift/SwiftUI) that monitors Warp terminal AI token usage in real-time. It reads usage data from Warp's preferences plist and displays it in a popover with progress bars and status cards.

## Build & Test

```bash
swift build                            # Debug build
swift build -c release                 # Release build
swift test                             # Run all tests
swift test --filter WarpUsageServiceTests  # Run specific test file
./build_app.sh                         # Create .app bundle
./run.sh                               # Build and run
```

- **Swift tools version**: 5.9
- **Minimum deployment**: macOS 14.0 (Sonoma)
- **No external dependencies** — only Apple frameworks (SwiftUI, AppKit, Combine, UserNotifications, ServiceManagement)
- **No Xcode project** — pure Swift Package Manager

## Project Structure

```
Sources/
  main.swift                 # Entry point, AppDelegate
  WarpUsageService.swift     # Core service: reads plist, parses AI usage, publishes updates
  MenuBarController.swift    # Menu bar button, popover, 1s refresh timer
  ContentView.swift          # SwiftUI popover UI (liquid glass design)
  PreferencesView.swift      # Settings window
  NotificationService.swift  # Warning/critical usage alerts
  Configuration.swift        # Centralized constants (AppConfiguration struct)
  StatusBarManaging.swift    # Protocol for status bar abstraction (DI)
  Resources/menubar_icon.png
Tests/WarpStatusTests/
  MockUtilities.swift        # Shared mocks and test helpers
  WarpUsageServiceTests.swift
  ViewTests.swift
  IntegrationTests.swift
  MenuBarControllerTests.swift
  ConfigurationTests.swift
```

## Architecture

- **MVVM** with `ObservableObject` + `@Published` for reactive data flow
- **Combine** publishers for change propagation
- **Dependency injection** via constructor (MenuBarController accepts services)
- **Protocol-oriented**: `StatusBarManaging` abstracts system dependencies for testability
- **DispatchSource** file monitoring for real-time plist change detection
- Data source: `~/Library/Preferences/dev.warp.Warp-Stable.plist`

## Code Conventions

- **Naming**: PascalCase for types, camelCase for properties/methods
- **Test naming**: `test{Feature}{Scenario}()`
- **Indentation**: 4 spaces
- **File naming**: test files mirror source files as `{ClassName}Tests.swift`
- **Comments**: `// MARK:` for sections; comments only where logic isn't self-evident
- **Error handling**: `WarpError` enum for typed errors
- **Trailing newlines**: enforced on all files

## Testing Philosophy

- Honest coverage (~60% overall); acknowledge untestable areas (SwiftUI rendering, AppKit system APIs)
- Mock objects in `MockUtilities.swift` for service isolation
- `TestConstants` for magic numbers, `TestHelpers` for DRY setup
- Integration tests verify component interaction
- No linter or formatter configured

## Key Implementation Details

- 1-second refresh timer for usage updates
- Smart file-change detection avoids redundant plist parsing
- Subscription detection based on usage limits and feature flags
- Exponential backoff retry (1s, 2s, 4s) for file access failures
- Proper resource cleanup in `deinit`
- No dock icon (menu bar–only app)
