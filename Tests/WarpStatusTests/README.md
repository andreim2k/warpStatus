# WarpStatus Test Suite

This directory contains comprehensive tests for the WarpStatus application, covering all major components and functionality.

## Test Structure

### 📁 Test Files

- **`MockUtilities.swift`** - Mock objects, test helpers, and utilities for isolated testing
- **`WarpUsageServiceTests.swift`** - Tests for the core WarpUsageService and WarpUsageData
- **`MenuBarControllerTests.swift`** - Tests for the MenuBarController and UI management
- **`ViewTests.swift`** - Tests for SwiftUI views and user interface components
- **`IntegrationTests.swift`** - End-to-end integration tests and system-wide functionality

### 🧪 Test Categories

#### 1. WarpUsageService Tests
- **Initialization**: Proper setup and configuration
- **WarpUsageData**: Data structure validation and computed properties
- **Subscription Detection**: Free, Basic, Standard, and Pro plan detection
- **Usage Calculations**: Percentage calculations and display text generation
- **Data Loading**: File system operations and plist parsing
- **Error Handling**: Comprehensive error types and recovery
- **Performance**: Data loading and processing performance
- **Thread Safety**: Concurrent access and thread safety
- **Memory Management**: Proper cleanup and resource management

#### 2. MenuBarController Tests
- **Initialization**: Proper setup and configuration
- **Status Bar Integration**: Menu bar item creation and management
- **Popover Management**: Popover creation, configuration, and behavior
- **Timer Management**: Real-time update timer setup and management
- **Event Handling**: User interaction and event monitoring
- **WarpUsageService Integration**: Data binding and updates
- **Memory Management**: Proper cleanup and resource management
- **Thread Safety**: Concurrent access and thread safety
- **Performance**: Initialization and update performance

#### 3. View Tests
- **Component Initialization**: SwiftUI view creation and setup
- **Data Binding**: Integration with WarpUsageService data
- **UI Updates**: Response to data changes and updates
- **Animation**: Animation support and behavior
- **Accessibility**: Accessibility features and support
- **Performance**: View creation and rendering performance
- **Edge Cases**: Handling of extreme values and error conditions
- **Layout**: View layout and composition

#### 4. Integration Tests
- **End-to-End Flow**: Complete system functionality
- **Data Flow**: Data propagation through the system
- **Performance Integration**: System performance under load
- **Error Handling**: System-wide error handling and recovery
- **Thread Safety**: Concurrent access and thread safety
- **Resource Management**: Memory and resource management
- **Real-time Updates**: Live data updates and monitoring
- **System State**: State consistency and transitions

#### 5. Mock Utilities
- **MockWarpUsageData**: Simulated usage data for testing
- **MockWarpUsageService**: Simulated service for isolated testing
- **TestHelpers**: Utility functions and test data creation
- **TestConstants**: Common test values and timeouts
- **TestExpectations**: Async testing utilities and helpers

## Running Tests

### Quick Start
```bash
# Run all tests
swift test

# Or run tests directly with Swift
swift test
```

### Individual Test Files
```bash
# Run specific test file
swift test --filter WarpUsageServiceTests
swift test --filter MenuBarControllerTests
swift test --filter ViewTests
swift test --filter IntegrationTests
```

### Test Coverage
```bash
# Generate test coverage report
swift test --enable-code-coverage
```

## Test Philosophy

### 🎯 Testing Principles
1. **Comprehensive Coverage**: Test all public APIs and critical paths
2. **Isolation**: Use mocks and stubs for isolated testing
3. **Realistic Data**: Use realistic test data and scenarios
4. **Performance**: Include performance tests for critical operations
5. **Edge Cases**: Test boundary conditions and error scenarios
6. **Integration**: Verify components work together correctly

### 🔧 Testing Strategies
- **Unit Tests**: Individual component testing with mocks
- **Integration Tests**: End-to-end functionality testing
- **Performance Tests**: Load and performance validation
- **Async Tests**: Proper handling of asynchronous operations
- **Error Tests**: Error handling and recovery validation

## Mock Data

### WarpUsageData Mock Data
```swift
// Default mock data
requestsUsed: 224
requestsLimit: 2500
nextRefreshTime: Date().addingTimeInterval(86400) // 24 hours from now
isUnlimited: false
subscriptionType: "Standard"

// High usage scenario
requestsUsed: 2400
requestsLimit: 2500
subscriptionType: "Standard"

// Low usage scenario
requestsUsed: 50
requestsLimit: 2500
subscriptionType: "Standard"

// Unlimited scenario
requestsUsed: 9999
requestsLimit: 0
isUnlimited: true
subscriptionType: "Pro"
```

### Test Constants
```swift
// Timeouts
defaultTimeout: 1.0 seconds
longTimeout: 5.0 seconds
shortTimeout: 0.1 seconds

// Mock values
mockRequestsUsed: 224
mockRequestsLimit: 2500
mockUsagePercentage: 0.0896 // 224/2500

// Subscription types
freePlan: "Free"
basicPlan: "Basic"
standardPlan: "Standard"
proPlan: "Pro"

// Test scenarios
highUsagePercentage: 0.95
mediumUsagePercentage: 0.75
lowUsagePercentage: 0.25

// Date constants
oneDayFromNow: 86400 seconds
oneWeekFromNow: 604800 seconds
oneMonthFromNow: 2592000 seconds
```

## Best Practices

### ✅ Do's
- Use descriptive test names that explain what is being tested
- Test both happy path and error scenarios
- Use mocks for external dependencies
- Include performance tests for critical operations
- Test edge cases and boundary conditions
- Use async testing utilities for asynchronous operations
- Clean up resources in tearDown methods

### ❌ Don'ts
- Don't test implementation details, test behavior
- Don't rely on external systems in unit tests
- Don't ignore test failures or warnings
- Don't create tests that are too complex or hard to understand
- Don't skip error handling tests
- Don't use real system resources in tests

## Troubleshooting

### Common Issues
1. **Test Timeouts**: Increase timeout values for slow operations
2. **Mock Data**: Ensure mock data is properly configured
3. **Async Operations**: Use proper async testing utilities
4. **Memory Leaks**: Check for proper cleanup in tearDown methods
5. **Thread Safety**: Test concurrent access scenarios

### Debug Tips
- Use `print()` statements for debugging test execution
- Check test output for detailed error messages
- Use Xcode's test navigator for interactive debugging
- Verify mock data is being used correctly
- Check for proper resource cleanup

## Contributing

When adding new tests:
1. Follow the existing test structure and naming conventions
2. Add appropriate mock data and test helpers
3. Include both positive and negative test cases
4. Add performance tests for new functionality
5. Update this README if adding new test categories

## Test Metrics

The test suite provides comprehensive coverage of:
- **Core Functionality**: WarpUsageService data collection and processing
- **User Interface**: SwiftUI views and user interactions
- **System Integration**: Menu bar integration and system APIs
- **Performance**: Resource usage and efficiency
- **Error Handling**: Graceful handling of errors and edge cases
- **Real-time Updates**: Live data monitoring and updates
- **Subscription Detection**: Intelligent plan type determination
- **Usage Calculations**: Accurate percentage and display text generation

This ensures WarpStatus is robust, reliable, and ready for production use.

## WarpStatus-Specific Features

### Subscription Type Detection
Tests verify intelligent subscription type detection based on:
- `is_unlimited` flag for Pro unlimited plans
- Voice request limits (999999+ indicates Pro)
- Max codebase indices (40+ indicates Pro)
- Request limits (2500+ Standard, 150+ Basic, <150 Free)

### Real-time Updates
Tests verify 1-second polling interval for responsive updates:
- File modification checking prevents unnecessary processing
- Immediate UI updates when Warp AI features are used
- Color-coded visual feedback for usage thresholds

### Data Flow
Tests verify complete data flow:
1. WarpUsageService monitors `~/Library/Preferences/dev.warp.Warp-Stable.plist`
2. File change detection prevents unnecessary parsing
3. JSON parsing extracts AI request limits from embedded JSON strings
4. Usage calculation determines percentage, subscription type, and refresh dates
5. Reactive updates trigger UI changes through ObservableObject publishers
6. Menu bar display shows real-time colored usage indicators
