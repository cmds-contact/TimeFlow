#!/bin/bash
# 이미 빌드된 앱 바로 실행 (빌드 없이)

cd "$(dirname "$0")/.."

APP_PATH="$(xcodebuild -project TimeFlow.xcodeproj -scheme TimeFlow -showBuildSettings 2>/dev/null | grep -m 1 'BUILT_PRODUCTS_DIR' | awk '{print $3}')/TimeFlow.app"

if [ -d "$APP_PATH" ]; then
    echo "🚀 Launching TimeFlow..."
    open "$APP_PATH"
    echo "✅ Done!"
else
    echo "❌ App not found. Please build first (use 1_Build_Run)"
fi
sleep 2
