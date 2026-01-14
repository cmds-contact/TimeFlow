# TimeFlow

A macOS time management app that helps you plan, track, and optimize your daily schedule.

## Features

- **Calendar View** - 24-hour timeline with drag-and-drop time block planning
- **Time Tracking** - Record actual time spent with timer or manual entry
- **Task Management** - Daily task list with estimated time and load indicators
- **Pomodoro Timer** - Focus sessions with break cycles and crash recovery
- **Plan vs Actual** - Overlay view to compare planned and actual time usage

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later (for building)

## Quick Start

```bash
# Clone the repository
git clone https://github.com/cmds-contact/TimeFlow.git
cd TimeFlow

# Generate Xcode project and run
make run
```

## Build Commands

```bash
# Generate Xcode project
make generate

# Build
make build

# Run tests
make test

# Run the app
make run

# Open in Xcode
make open

# Clean build artifacts
make clean
```

## Project Structure

```
TimeFlow/
├── App/                    # App entry point, DI container
├── Core/
│   ├── Time/              # Time calculation utilities
│   ├── Timer/             # Timer service with persistence
│   └── Settings/          # User preferences
├── Data/
│   ├── SwiftData/Models/  # Data models
│   └── Repositories/      # Data access layer
├── Domain/
│   └── UseCases/          # Business logic
├── Features/
│   ├── Calendar/          # Calendar view & time blocks
│   ├── Tasks/             # Task list & daily load
│   ├── Focus/             # Pomodoro timer
│   └── Settings/          # Settings UI
└── Tests/                 # Unit & UI tests
```

## Tech Stack

| Component | Technology |
|-----------|------------|
| UI | SwiftUI |
| Data | SwiftData |
| Project | XcodeGen |
| Timer | swift-persistable-timer |
| Architecture | Clean Architecture + MVVM |

## Documentation

- [Architecture](docs/ARCHITECTURE.md) - Technical architecture overview
- [Git Workflow](docs/GIT_WORKFLOW.md) - Branch strategy and workflow
- [Contributing](CONTRIBUTING.md) - How to contribute

## License

MIT License - See [LICENSE](LICENSE) for details.
