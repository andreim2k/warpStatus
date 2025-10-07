#!/usr/bin/env swift

import Foundation

/// Build Verifier for WarpStatus
///
/// This script verifies that the project is properly configured and can be built.
/// It does NOT run actual XCTest tests - use `swift test` for that.

print("🔧 WarpStatus Build Verification")
print("================================\n")

var hasErrors = false

// MARK: - Build Test

print("📦 Building WarpStatus...")

let buildTask = Process()
buildTask.launchPath = "/usr/bin/swift"
buildTask.arguments = ["build"]

let buildPipe = Pipe()
buildTask.standardOutput = buildPipe
buildTask.standardError = buildPipe

buildTask.launch()
buildTask.waitUntilExit()

if buildTask.terminationStatus == 0 {
    print("✅ Build successful")
} else {
    print("❌ Build failed")
    let buildData = buildPipe.fileHandleForReading.readDataToEndOfFile()
    if let buildOutput = String(data: buildData, encoding: .utf8) {
        print("\n--- Build Output ---")
        print(buildOutput)
        print("--- End Output ---\n")
    }
    hasErrors = true
}

// MARK: - Executable Verification

print("\n🔧 Verifying executable...")

let executablePath = ".build/debug/WarpStatus"
if FileManager.default.fileExists(atPath: executablePath) {
    print("✅ Executable exists at: \(executablePath)")

    // Check permissions
    do {
        let attributes = try FileManager.default.attributesOfItem(atPath: executablePath)
        if let permissions = attributes[.posixPermissions] as? NSNumber {
            let perms = permissions.intValue
            if perms & 0o111 != 0 {
                print("✅ Executable has proper permissions")
            } else {
                print("❌ Executable lacks execute permissions")
                hasErrors = true
            }
        }
    } catch {
        print("⚠️  Could not check executable permissions: \(error)")
    }
} else {
    print("❌ Executable not found")
    hasErrors = true
}

// MARK: - Source Files Verification

print("\n📁 Verifying source files...")

let requiredSourceFiles = [
    "Sources/main.swift",
    "Sources/WarpUsageService.swift",
    "Sources/MenuBarController.swift",
    "Sources/ContentView.swift"
]

var missingFiles = false
for file in requiredSourceFiles {
    if FileManager.default.fileExists(atPath: file) {
        print("✅ \(file)")
    } else {
        print("❌ \(file) - MISSING")
        missingFiles = true
        hasErrors = true
    }
}

if !missingFiles {
    print("✅ All source files present")
}

// MARK: - Test Files Verification

print("\n🧪 Verifying test files...")

let requiredTestFiles = [
    "Tests/WarpStatusTests/MockUtilities.swift",
    "Tests/WarpStatusTests/WarpUsageServiceTests.swift",
    "Tests/WarpStatusTests/MenuBarControllerTests.swift",
    "Tests/WarpStatusTests/ViewTests.swift",
    "Tests/WarpStatusTests/IntegrationTests.swift"
]

var missingTestFiles = false
for file in requiredTestFiles {
    if FileManager.default.fileExists(atPath: file) {
        print("✅ \(file)")
    } else {
        print("❌ \(file) - MISSING")
        missingTestFiles = true
        hasErrors = true
    }
}

if !missingTestFiles {
    print("✅ All test files present")
}

// MARK: - Package Configuration

print("\n📋 Verifying Package.swift...")

if FileManager.default.fileExists(atPath: "Package.swift") {
    print("✅ Package.swift exists")

    do {
        let packageContent = try String(contentsOfFile: "Package.swift", encoding: .utf8)

        if packageContent.contains("WarpStatus") {
            print("✅ Package.swift contains WarpStatus target")
        } else {
            print("❌ Package.swift missing WarpStatus target")
            hasErrors = true
        }

        if packageContent.contains("WarpStatusTests") {
            print("✅ Package.swift contains test target")
        } else {
            print("⚠️  Package.swift missing WarpStatusTests target")
        }
    } catch {
        print("❌ Could not read Package.swift: \(error)")
        hasErrors = true
    }
} else {
    print("❌ Package.swift not found")
    hasErrors = true
}

// MARK: - Documentation

print("\n📚 Verifying documentation...")

let documentationFiles = [
    "README.md",
    "WARP.md",
    "APP_USAGE.md",
    "Tests/WarpStatusTests/README.md"
]

for file in documentationFiles {
    if FileManager.default.fileExists(atPath: file) {
        print("✅ \(file)")
    } else {
        print("⚠️  \(file) - missing (optional)")
    }
}

// MARK: - Build Scripts

print("\n🔨 Verifying build scripts...")

let buildScripts = [
    "build_app.sh",
    "launch_app.sh",
    "run.sh",
    "uninstall.sh"
]

for script in buildScripts {
    if FileManager.default.fileExists(atPath: script) {
        print("✅ \(script) exists")

        // Check if executable
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: script)
            if let permissions = attributes[.posixPermissions] as? NSNumber {
                let perms = permissions.intValue
                if perms & 0o111 != 0 {
                    // Is executable - no output needed, keep it clean
                } else {
                    print("   ⚠️  Not executable - run: chmod +x \(script)")
                }
            }
        } catch {
            print("   ⚠️  Could not check permissions")
        }
    } else {
        print("⚠️  \(script) - missing (optional)")
    }
}

// MARK: - Summary

print("\n" + String(repeating: "=", count: 50))
print("📊 Verification Summary")
print(String(repeating: "=", count: 50))

if hasErrors {
    print("❌ Verification FAILED - errors found above")
    print("\nPlease fix the errors and run this script again.")
    exit(1)
} else {
    print("✅ All verifications passed!")
    print("\n🎉 WarpStatus is ready for development and testing!")

    print("\n💡 Next Steps:")
    print("   • Run tests:       swift test")
    print("   • Run app:         ./run.sh")
    print("   • Build app:       ./build_app.sh")
    print("   • Run verifier:    swift build_verifier.swift")
}

print("")
