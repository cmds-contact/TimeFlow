#!/bin/bash
# 앱 종료

echo "🛑 Closing TimeFlow..."
pkill -x TimeFlow 2>/dev/null && echo "✅ TimeFlow closed" || echo "ℹ️  TimeFlow is not running"
sleep 2
