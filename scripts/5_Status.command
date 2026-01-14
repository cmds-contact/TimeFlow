#!/bin/bash
# 빌드 상태 확인

cd "$(dirname "$0")/.."

echo "📊 Build Status:"
echo ""

APP_PATH="$(xcodebuild -project TimeFlow.xcodeproj -scheme TimeFlow -showBuildSettings 2>/dev/null | grep -m 1 'BUILT_PRODUCTS_DIR' | awk '{print $3}')/TimeFlow.app"

if [ -d "$APP_PATH" ]; then
    echo "  ✅ App exists"
    echo "  📁 Path: $APP_PATH"
    echo "  📅 Last modified: $(stat -f '%Sm' "$APP_PATH")"
else
    echo "  ❌ App not built yet"
fi

echo ""
echo "🔄 Running processes:"
if pgrep -x TimeFlow >/dev/null; then
    echo "  ✅ TimeFlow is running (PID: $(pgrep -x TimeFlow))"
else
    echo "  ⏹️  TimeFlow is not running"
fi

echo ""
echo "Press any key to close..."
read -n 1
