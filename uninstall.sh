#!/bin/bash

echo "🗑️  Uninstalling WarpStatus..."

# Kill the running app if it exists
pkill -f WarpStatus >/dev/null 2>&1

# Remove from Applications
if [ -d "/Applications/WarpStatus.app" ]; then
    rm -rf "/Applications/WarpStatus.app"
    echo "✅ Removed WarpStatus.app from Applications folder"
else
    echo "❌ WarpStatus.app not found in Applications"
fi

echo "🎯 Uninstall complete!"