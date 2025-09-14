# WarpStatus - Warp Terminal AI Usage Monitor

A macOS menu bar application that displays your Warp terminal AI usage in real-time.

![WarpStatus Demo](demo.png)

## Features

- **Real-time Usage Display**: Shows current AI request usage (e.g., 224/2500) directly in the menu bar
- **Color-coded Status**: Green for healthy usage, orange for moderate, red for near limit
- **Subscription Type**: Displays your plan type (Free, Standard, Pro)
- **Progress Visualization**: Visual progress bar showing usage percentage
- **Real-time Updates**: Updates every second for instant usage tracking
- **Manual Refresh**: Click to refresh usage data instantly
- **Reset Timer**: Shows when your usage limit will reset

## How it Works

WarpStatus monitors your Warp AI usage in real-time by reading from Warp's local preferences file (`~/Library/Preferences/dev.warp.Warp-Stable.plist`). It updates every second to show instant changes when you use AI features, displaying this information in an easy-to-read menu bar format.

## Installation & Usage

### Option 1: Run from Source (Recommended)

1. Clone or download this repository
2. Navigate to the project directory:
   ```bash
   cd /Users/andrei/Hobby/warpStatus
   ```
3. Run the application:
   ```bash
   ./run.sh
   ```
   
   Or manually:
   ```bash
   swift run WarpStatus
   ```

### Option 2: Build Executable

1. Build the application:
   ```bash
   swift build -c release
   ```
2. Copy the executable:
   ```bash
   cp .build/release/WarpStatus /usr/local/bin/
   ```
3. Run from anywhere:
   ```bash
   WarpStatus
   ```

## Menu Features

When you click on the menu bar item, you'll see:

- **Current Usage**: Your current AI request count and limit
- **Plan Type**: Your subscription plan (Free Plan, Pro Plan, etc.)
- **Progress Bar**: Visual representation of usage percentage
- **Reset Date**: When your usage counter will reset
- **Live Updates**: Shows "🔄 Live Updates (1s refresh)" indicator
- **Manual Refresh**: Instantly update the data
- **Quit Option**: Close the application

## Menu Bar Display

The menu bar shows:
- 🖥️ Terminal icon
- Current usage (e.g., "224/2500")
- Color coding:
  - **Green**: < 70% usage
  - **Orange**: 70-90% usage  
  - **Red**: > 90% usage
  - **Green with ∞**: Unlimited plan

## Requirements

- macOS 14.0 or later
- Warp Terminal installed
- Swift 5.9 or later (for building from source)

## Troubleshooting

### "Error: Warp preferences file not found"
- Make sure Warp Terminal is installed and you've used AI features at least once
- The app looks for: `~/Library/Preferences/dev.warp.Warp-Stable.plist`

### "Error: Unable to parse Warp usage data"
- Try refreshing the data manually
- Restart Warp Terminal if the issue persists
- Check that you have the latest version of Warp

### Menu bar item not appearing
- The app runs as a menu bar utility (no dock icon)
- Look for the terminal icon in your menu bar
- Try running from Terminal to see any error messages

## Privacy

WarpStatus only reads local preference files stored on your Mac by Warp Terminal. No data is sent to external servers or third parties.

## License

This project is provided as-is for personal use. Feel free to modify and distribute according to your needs.

## Contributing

Feel free to submit issues, suggestions, or pull requests to improve WarpStatus!