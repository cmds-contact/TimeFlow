#!/bin/bash
# 앱 종료 후 다시 빌드 & 실행

cd "$(dirname "$0")/.."

echo "🛑 Closing TimeFlow..."
pkill -x TimeFlow 2>/dev/null || true
sleep 0.5

echo "🔨 Building TimeFlow..."
echo ""

xcodebuild -project TimeFlow.xcodeproj \
    -scheme TimeFlow \
    -configuration Debug \
    -destination 'platform=macOS' \
    build 2>&1 | grep -E '(error:|warning:|BUILD|Compiling)' || true

echo ""
echo "🚀 Launching TimeFlow..."
sleep 1

APP_PATH="$(xcodebuild -project TimeFlow.xcodeproj -scheme TimeFlow -showBuildSettings 2>/dev/null | grep -m 1 'BUILT_PRODUCTS_DIR' | awk '{print $3}')/TimeFlow.app"
open "$APP_PATH"

echo ""
echo "✅ Done!"
sleep 2
