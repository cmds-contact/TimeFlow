.PHONY: generate build run clean open

# Generate Xcode project from project.yml
generate:
	xcodegen generate

# Build the app
build: generate
	xcodebuild -scheme TimeFlow -configuration Debug build

# Run the app
run: build
	open build/Debug/TimeFlow.app

# Clean build artifacts
clean:
	xcodebuild clean
	rm -rf build/

# Open in Xcode
open: generate
	open TimeFlow.xcodeproj
