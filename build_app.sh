#!/bin/bash

# Build WarpStatus as proper macOS app bundle
# Usage: ./build_app.sh

echo "🔨 Building WarpStatus..."
swift build -c release

echo "📦 Creating app bundle..."
rm -rf /Applications/WarpStatus.app
mkdir -p /Applications/WarpStatus.app/Contents/MacOS

echo "📋 Copying executable..."
cp .build/arm64-apple-macosx/release/WarpStatus /Applications/WarpStatus.app/Contents/MacOS/WarpStatus

echo "📄 Creating Info.plist..."
cat > /Applications/WarpStatus.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDisplayName</key>
	<string>Warp Status</string>
	<key>CFBundleExecutable</key>
	<string>WarpStatus</string>
	<key>CFBundleIdentifier</key>
	<string>com.andrei.warpstatus</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>WarpStatus</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>2.0</string>
	<key>CFBundleVersion</key>
	<string>2</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSSupportsAutomaticGraphicsSwitching</key>
	<true/>
</dict>
</plist>
EOF

echo "🚀 Launching WarpStatus.app..."
pkill -f WarpStatus 2>/dev/null
open /Applications/WarpStatus.app

echo "✅ WarpStatus deployed successfully as proper macOS app!"
echo "   Location: /Applications/WarpStatus.app"
echo "   Menu Bar: Look for terminal icon with remaining token count"
echo "   Popup: Click icon to see detailed usage breakdown"