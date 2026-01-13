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
