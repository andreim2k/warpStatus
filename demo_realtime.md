# 🚀 Real-Time Updates Demo

## How to Test Real-Time Updates

1. **Start WarpStatus**:
   ```bash
   ./run.sh
   ```

2. **Open the test monitor** (in a separate terminal):
   ```bash
   ./test_realtime.swift
   ```

3. **Use Warp AI features**:
   - Ask a question in Warp terminal
   - Use Agent Mode
   - Generate code completions

4. **Watch the magic** ✨:
   - WarpStatus menu bar updates instantly
   - Test monitor shows file changes
   - Usage counter increments in real-time

## What You'll See

### Menu Bar:
- 🖥️ **224/2500** → **225/2500** (instant update)
- Color changes as you approach limits

### Menu Dropdown:
- **Usage**: 225/2500 
- **Plan**: Pro Plan
- **Progress**: [██░░░░░░░░] 9% → 10%
- **🔄 Live Updates (1s refresh)**
- **Last updated**: 2:34:55 PM

### Test Monitor Output:
```
🔄 Monitoring Warp usage file for changes...
📁 File: /Users/andrei/Library/Preferences/dev.warp.Warp-Stable.plist
⏰ Checking every second for updates...
💡 Use Warp AI features to see real-time changes!

[2:34:52 PM] 📝 File modified: 224/2500
[2:34:55 PM] 🔄 Usage updated: 225/2500
[2:34:58 PM] 🔄 Usage updated: 226/2500
```

## Performance Notes

- **Smart Caching**: Only updates when files actually change
- **Low CPU Usage**: File modification checking is very efficient  
- **No Network**: All data is local, lightning fast
- **Battery Friendly**: Minimal impact on system resources

## Clean Up

Stop the test monitor with `Ctrl+C` when done testing.