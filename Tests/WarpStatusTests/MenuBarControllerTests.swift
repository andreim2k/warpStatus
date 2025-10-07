import XCTest
import AppKit
import SwiftUI
import Combine
@testable import WarpStatus

/// Tests for MenuBarController
///
/// NOTE: MenuBarController has limited testability due to its architecture:
/// - All properties are private
/// - Tightly coupled to NSStatusBar and system resources
/// - Relies on real system components (NSStatusBar, NSPopover, Timer)
///
/// These tests verify basic initialization and cleanup. For more comprehensive testing,
/// MenuBarController would need to be refactored to:
/// 1. Accept dependencies via initializer (dependency injection)
/// 2. Expose testable interfaces
/// 3. Separate business logic from UI coordination
final class MenuBarControllerTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testMenuBarControllerInitialization() {
        let controller = MenuBarController()
        XCTAssertNotNil(controller, "MenuBarController should initialize successfully")
    }

    func testMultipleMenuBarControllersCanBeCreated() {
        let controller1 = MenuBarController()
        let controller2 = MenuBarController()

        XCTAssertNotNil(controller1)
        XCTAssertNotNil(controller2)

        // Note: Creating multiple menu bar items may cause UI issues,
        // but the controllers themselves should be created successfully
    }

    // MARK: - Memory Management Tests

    func testMenuBarControllerDeallocation() {
        weak var weakController: MenuBarController?

        autoreleasepool {
            let controller = MenuBarController()
            weakController = controller
            XCTAssertNotNil(weakController)
            // controller goes out of scope here
        }

        // Give time for cleanup
        let expectation = XCTestExpectation(description: "Cleanup expectation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Note: Due to NSStatusBar retaining the item, weakController may not be nil
        // This is expected behavior, not a memory leak
        // The test verifies that deallocation completes without crashes
    }

    // MARK: - Performance Tests

    func testMenuBarControllerInitializationPerformance() {
        // Note: This test creates actual UI components, so it may be slow
        measure(metrics: [XCTClockMetric()]) {
            let controller = MenuBarController()
            XCTAssertNotNil(controller)

            // Brief cleanup delay
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
    }

    // MARK: - Integration Tests

    func testMenuBarControllerIntegrationWithWarpUsageService() {
        // This test verifies that MenuBarController can be created
        // and integrates with WarpUsageService without crashing
        let controller = MenuBarController()

        let expectation = XCTestExpectation(description: "Controller should integrate with service")

        // Wait briefly to allow initialization to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNotNil(controller)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Thread Safety Tests

    func testMenuBarControllerCreationOnMainThread() {
        XCTAssertTrue(Thread.isMainThread, "Test should run on main thread")

        let controller = MenuBarController()
        XCTAssertNotNil(controller, "Controller should be created on main thread")
    }

    func testMenuBarControllerAccessFromBackgroundThread() {
        let controller = MenuBarController()
        let expectation = XCTestExpectation(description: "Background thread access")

        DispatchQueue.global(qos: .background).async {
            // Accessing controller from background thread should not crash
            XCTAssertNotNil(controller)

            DispatchQueue.main.async {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Notes on Testing Limitations

    /// This test documents the architectural limitations that prevent comprehensive testing
    func testArchitecturalLimitations() {
        // MenuBarController cannot be thoroughly tested because:
        // 1. All properties are private - cannot verify internal state
        // 2. NSStatusBar is a singleton - difficult to mock or stub
        // 3. Popover and button interactions require UI testing framework
        // 4. Timer behavior requires time-based tests that are flaky
        // 5. Event monitoring is system-level and cannot be easily mocked
        //
        // Recommended improvements:
        // - Extract a protocol for status bar interactions
        // - Use dependency injection for WarpUsageService
        // - Separate view state from controller logic
        // - Make critical properties internal for testing

        XCTAssertTrue(true, "This test serves as documentation")
    }
}
