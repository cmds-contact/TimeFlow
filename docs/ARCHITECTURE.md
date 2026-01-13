# TimeFlow Architecture

This document describes the technical architecture of TimeFlow.

## Overview

TimeFlow follows **Clean Architecture** principles with clear separation of concerns across four layers.

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  (SwiftUI Views, ViewModels)                                │
├─────────────────────────────────────────────────────────────┤
│                       Domain Layer                           │
│  (UseCases, Business Logic)                                 │
├─────────────────────────────────────────────────────────────┤
│                        Data Layer                            │
│  (Repositories, SwiftData Models)                           │
├─────────────────────────────────────────────────────────────┤
│                        Core Layer                            │
│  (Time Utilities, Timer Service, Settings)                  │
└─────────────────────────────────────────────────────────────┘
```

## Layer Dependencies

```
Presentation  →  Domain  →  Data
      ↓            ↓         ↓
           Core (shared utilities)
```

- **Presentation** depends on Domain and Core
- **Domain** depends on Data and Core
- **Data** depends on Core
- **Core** has no internal dependencies

## Layers

### 1. Presentation Layer (`Features/`)

Contains SwiftUI views organized by feature:

```
Features/
├── Calendar/Views/
│   ├── CalendarView.swift        # Main calendar container
│   ├── TimelineGridView.swift    # 24-hour grid
│   ├── PlanBlockView.swift       # Plan block component
│   └── ActualBlockView.swift     # Actual block component
├── Tasks/Views/
│   ├── TaskListView.swift        # Task list container
│   ├── TaskRowView.swift         # Individual task row
│   └── DailyLoadIndicator.swift  # Load status display
├── Focus/Views/
│   ├── FocusView.swift           # Pomodoro container
│   └── PomodoroTimerView.swift   # Circular timer
└── Settings/Views/
    └── SettingsView.swift        # Settings tabs
```

**Rules:**
- Views should be thin - delegate logic to UseCases
- Use `@EnvironmentObject` for shared state
- Never call repositories directly

### 2. Domain Layer (`Domain/UseCases/`)

Contains business logic organized by feature:

```
Domain/UseCases/
├── Calendar/
│   ├── CreatePlanBlockUseCase.swift
│   ├── UpdatePlanBlockUseCase.swift
│   ├── DeletePlanBlockUseCase.swift
│   └── FetchPlanBlocksUseCase.swift
├── Tracking/
│   ├── StartTrackingUseCase.swift
│   ├── StopTrackingUseCase.swift
│   └── LinkActualToPlanUseCase.swift
├── Tasks/
│   ├── CreateTaskUseCase.swift
│   ├── CompleteTaskUseCase.swift
│   └── CalculateDailyLoadUseCase.swift
└── Focus/
    ├── StartPomodoroUseCase.swift
    ├── PausePomodoroUseCase.swift
    └── CompleteCycleUseCase.swift
```

**Rules:**
- Each UseCase has a single responsibility
- UseCases coordinate between repositories and services
- Business rules are enforced here

### 3. Data Layer (`Data/`)

Contains data models and repository implementations:

```
Data/
├── SwiftData/Models/
│   ├── PlanBlockModel.swift      # Planned time blocks
│   ├── ActualBlockModel.swift    # Recorded time blocks
│   ├── TaskItemModel.swift       # Tasks with estimates
│   ├── PomodoroSessionModel.swift # Focus sessions
│   └── CategoryModel.swift       # Block categories
└── Repositories/
    ├── PlanBlockRepository.swift
    ├── ActualBlockRepository.swift
    ├── TaskRepository.swift
    └── PomodoroRepository.swift
```

**Rules:**
- Models are SwiftData `@Model` classes
- Repositories handle all CRUD operations
- Data validation happens at repository level

### 4. Core Layer (`Core/`)

Contains shared utilities and services:

```
Core/
├── Time/
│   ├── TimeSlot.swift           # Time range value type
│   ├── TimeCalculator.swift     # Time calculations
│   ├── TimeFormatter.swift      # Duration formatting
│   └── DateExtensions.swift     # Date helpers
├── Timer/
│   ├── TimerState.swift         # Timer state enums
│   └── TimerService.swift       # Persistent timer
└── Settings/
    └── UserSettings.swift       # User preferences
```

**Rules:**
- Core has no dependencies on other layers
- All time calculations go through `TimeCalculator`
- Timer state is persisted for crash recovery

## Data Flow

### Creating a Plan Block

```
User Interaction
       ↓
CalendarView (tap on timeline)
       ↓
PlanBlockEditorSheet (input form)
       ↓
CreatePlanBlockUseCase.execute()
       ↓
TimeCalculator.isValidSlot() ← validates time range
       ↓
PlanBlockRepository.create() ← persists to SwiftData
       ↓
@Query updates CalendarView automatically
```

### Starting Pomodoro Timer

```
User Interaction
       ↓
FocusView (tap Start)
       ↓
StartPomodoroUseCase.execute()
       ↓
PomodoroRepository.create() ← creates session record
       ↓
TimerService.startCountdown() ← starts persistent timer
       ↓
Timer ticks → UI updates via @Published
       ↓
On completion → CompleteCycleUseCase
       ↓
ActualBlockRepository.create() ← records focus time
```

## Dependency Injection

Dependencies are managed through `AppEnvironment`:

```swift
@MainActor
final class AppEnvironment: ObservableObject {
    let modelContainer: ModelContainer
    let userSettings: UserSettings
    let timeCalculator: TimeCalculator

    lazy var planBlockRepository: PlanBlockRepository
    lazy var timerService: TimerService
    lazy var useCases: UseCases
}
```

Views access dependencies via `@EnvironmentObject`:

```swift
struct CalendarView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment

    var body: some View {
        // Use appEnvironment.useCases
    }
}
```

## Key Design Decisions

### 1. SwiftData over Core Data
- Modern, macro-based API
- Better SwiftUI integration
- Simplified model definitions

### 2. XcodeGen over Xcode project
- Git-friendly (no merge conflicts)
- CLI build support
- Reproducible builds

### 3. UseCase Pattern
- Keeps views thin
- Centralizes business logic
- Improves testability

### 4. Persistent Timer
- Uses `swift-persistable-timer` library
- Survives app termination
- Automatic state restoration

## Testing Strategy

| Layer | Test Type | Coverage |
|-------|-----------|----------|
| Core/Time | Unit tests | Time calculations |
| Domain/UseCases | Unit tests | Business logic |
| Data/Repositories | Integration tests | Data integrity |
| Features | UI tests | User workflows |
