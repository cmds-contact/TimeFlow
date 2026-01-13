.PHONY: setup generate build test clean archive run

# Install xcodegen if not present
setup:
	@command -v xcodegen >/dev/null 2>&1 || brew install xcodegen
	@echo "Setup complete"

# Generate Xcode project from project.yml
generate:
	xcodegen generate
	@echo "Project generated successfully"

# Build for macOS (Debug)
build: generate
	xcodebuild -project TimeFlow.xcodeproj \
		-scheme TimeFlow \
		-configuration Debug \
		-destination 'platform=macOS' \
		build

# Build for macOS (Release)
build-release: generate
	xcodebuild -project TimeFlow.xcodeproj \
		-scheme TimeFlow \
		-configuration Release \
		-destination 'platform=macOS' \
		build

# Run unit tests
test: generate
	xcodebuild -project TimeFlow.xcodeproj \
		-scheme TimeFlow \
		-configuration Debug \
		-destination 'platform=macOS' \
		test

# Run only unit tests (skip UI tests)
test-unit: generate
	xcodebuild -project TimeFlow.xcodeproj \
		-scheme TimeFlow \
		-configuration Debug \
		-destination 'platform=macOS' \
		-only-testing:TimeFlowTests \
		test

# Clean build artifacts
clean:
	xcodebuild clean -project TimeFlow.xcodeproj -scheme TimeFlow 2>/dev/null || true
	rm -rf DerivedData
	rm -rf build
	@echo "Clean complete"

# Clean and regenerate project
reset: clean
	rm -rf TimeFlow.xcodeproj
	xcodegen generate
	@echo "Project reset complete"

# Archive for release
archive: generate
	xcodebuild -project TimeFlow.xcodeproj \
		-scheme TimeFlow \
		-configuration Release \
		-destination 'platform=macOS' \
		archive \
		-archivePath ./build/TimeFlow.xcarchive

# Open in Xcode
open: generate
	open TimeFlow.xcodeproj

# Run the app (builds first if needed)
run: generate
	@echo "Building and running TimeFlow..."
	@xcodebuild -project TimeFlow.xcodeproj \
		-scheme TimeFlow \
		-configuration Debug \
		-destination 'platform=macOS' \
		build 2>&1 | tail -5
	@open "$$(xcodebuild -project TimeFlow.xcodeproj -scheme TimeFlow -showBuildSettings 2>/dev/null | grep -m 1 'BUILT_PRODUCTS_DIR' | awk '{print $$3}')/TimeFlow.app"

# Quick run (skip build if already built)
quick-run:
	@APP_PATH="$$(xcodebuild -project TimeFlow.xcodeproj -scheme TimeFlow -showBuildSettings 2>/dev/null | grep -m 1 'BUILT_PRODUCTS_DIR' | awk '{print $$3}')/TimeFlow.app"; \
	if [ -d "$$APP_PATH" ]; then \
		open "$$APP_PATH"; \
	else \
		echo "App not found. Run 'make run' first."; \
	fi

# ============================================
# 테스트 편의 명령어
# ============================================

# 빌드 후 바로 실행 (가장 많이 사용)
br: build-run
build-run:
	@echo "🔨 Building TimeFlow..."
	@xcodebuild -project TimeFlow.xcodeproj \
		-scheme TimeFlow \
		-configuration Debug \
		-destination 'platform=macOS' \
		build 2>&1 | grep -E '(error:|warning:|BUILD|Compiling)' || true
	@echo ""
	@echo "🚀 Launching TimeFlow..."
	@sleep 1
	@open "$$(xcodebuild -project TimeFlow.xcodeproj -scheme TimeFlow -showBuildSettings 2>/dev/null | grep -m 1 'BUILT_PRODUCTS_DIR' | awk '{print $$3}')/TimeFlow.app"

# 앱 종료 후 다시 빌드 & 실행
restart:
	@echo "🛑 Closing TimeFlow..."
	@pkill -x TimeFlow 2>/dev/null || true
	@sleep 0.5
	@$(MAKE) build-run

# 앱만 종료
kill:
	@pkill -x TimeFlow 2>/dev/null && echo "✅ TimeFlow closed" || echo "ℹ️  TimeFlow is not running"

# 빌드 상태 확인
status:
	@echo "📊 Build Status:"
	@APP_PATH="$$(xcodebuild -project TimeFlow.xcodeproj -scheme TimeFlow -showBuildSettings 2>/dev/null | grep -m 1 'BUILT_PRODUCTS_DIR' | awk '{print $$3}')/TimeFlow.app"; \
	if [ -d "$$APP_PATH" ]; then \
		echo "  ✅ App exists: $$APP_PATH"; \
		echo "  📅 Last modified: $$(stat -f '%Sm' "$$APP_PATH")"; \
	else \
		echo "  ❌ App not built yet"; \
	fi
	@echo ""
	@echo "🔄 Running processes:"
	@pgrep -x TimeFlow >/dev/null && echo "  ✅ TimeFlow is running (PID: $$(pgrep -x TimeFlow))" || echo "  ⏹️  TimeFlow is not running"

# 변경사항 확인 후 빌드 (git diff 보여줌)
dev:
	@echo "📝 Changed files:"
	@git diff --name-only 2>/dev/null || true
	@echo ""
	@$(MAKE) build-run

# 도움말
help:
	@echo "TimeFlow 개발 명령어"
	@echo "===================="
	@echo ""
	@echo "자주 사용하는 명령어:"
	@echo "  make br        - 빌드 후 실행 (= make build-run)"
	@echo "  make restart   - 앱 종료 → 빌드 → 실행"
	@echo "  make kill      - 앱 종료"
	@echo "  make status    - 빌드 상태 확인"
	@echo ""
	@echo "기본 명령어:"
	@echo "  make build     - Debug 빌드"
	@echo "  make run       - 빌드 후 실행"
	@echo "  make quick-run - 이미 빌드된 앱 실행"
	@echo "  make test      - 테스트 실행"
	@echo "  make clean     - 빌드 캐시 삭제"
	@echo "  make open      - Xcode에서 열기"
