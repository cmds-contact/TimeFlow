import Foundation

/// Represents the current state of a timer
enum TimerState: Equatable {
    /// Timer is not running
    case idle

    /// Timer is running (for manual tracking - stopwatch mode)
    case running(startedAt: Date)

    /// Timer is counting down (for Pomodoro)
    case countdown(startedAt: Date, remainingSeconds: Int)

    /// Timer is paused
    case paused(pausedAt: Date, elapsedSeconds: Int)

    // MARK: - Properties

    var isActive: Bool {
        switch self {
        case .running, .countdown:
            return true
        case .idle, .paused:
            return false
        }
    }

    var isPaused: Bool {
        if case .paused = self {
            return true
        }
        return false
    }

    var startedAt: Date? {
        switch self {
        case .running(let date):
            return date
        case .countdown(let date, _):
            return date
        case .paused:
            return nil
        case .idle:
            return nil
        }
    }

    /// Elapsed seconds for stopwatch mode
    var elapsedSeconds: Int {
        switch self {
        case .running(let startedAt):
            return Int(Date().timeIntervalSince(startedAt))
        case .paused(_, let elapsed):
            return elapsed
        case .countdown, .idle:
            return 0
        }
    }

    /// Remaining seconds for countdown mode
    var remainingSeconds: Int {
        switch self {
        case .countdown(_, let remaining):
            return remaining
        default:
            return 0
        }
    }
}

// MARK: - Pomodoro State

/// Represents the current phase of a Pomodoro session
enum PomodoroPhase: String, Codable, Equatable {
    case focus
    case shortBreak
    case longBreak

    var title: String {
        switch self {
        case .focus: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    var icon: String {
        switch self {
        case .focus: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer"
        case .longBreak: return "bed.double"
        }
    }
}

/// Represents the full state of a Pomodoro session
enum PomodoroState: Equatable {
    /// No active session
    case idle

    /// Currently in focus period
    case focusing(remainingSeconds: Int, cycle: Int, totalCycles: Int)

    /// Currently on break
    case breaking(remainingSeconds: Int, cycle: Int, totalCycles: Int, isLongBreak: Bool)

    /// Session is paused
    case paused(previousPhase: PomodoroPhase, remainingSeconds: Int, cycle: Int, totalCycles: Int)

    /// All cycles completed
    case completed(totalFocusMinutes: Int)

    // MARK: - Properties

    var isActive: Bool {
        switch self {
        case .focusing, .breaking:
            return true
        default:
            return false
        }
    }

    var isPaused: Bool {
        if case .paused = self {
            return true
        }
        return false
    }

    var currentPhase: PomodoroPhase? {
        switch self {
        case .focusing:
            return .focus
        case .breaking(_, _, _, let isLongBreak):
            return isLongBreak ? .longBreak : .shortBreak
        case .paused(let phase, _, _, _):
            return phase
        default:
            return nil
        }
    }

    var currentCycle: Int {
        switch self {
        case .focusing(_, let cycle, _):
            return cycle
        case .breaking(_, let cycle, _, _):
            return cycle
        case .paused(_, _, let cycle, _):
            return cycle
        default:
            return 0
        }
    }

    var totalCycles: Int {
        switch self {
        case .focusing(_, _, let total):
            return total
        case .breaking(_, _, let total, _):
            return total
        case .paused(_, _, _, let total):
            return total
        default:
            return 0
        }
    }

    var remainingSeconds: Int {
        switch self {
        case .focusing(let remaining, _, _):
            return remaining
        case .breaking(let remaining, _, _, _):
            return remaining
        case .paused(_, let remaining, _, _):
            return remaining
        default:
            return 0
        }
    }

    var progressPercentage: Double {
        switch self {
        case .focusing, .breaking, .paused:
            let current = Double(currentCycle)
            let total = Double(totalCycles)
            return total > 0 ? current / total : 0
        case .completed:
            return 1.0
        case .idle:
            return 0
        }
    }
}

// MARK: - Persisted Timer Data

/// Data structure for persisting timer state
struct PersistedTimerData: Codable {
    let type: TimerType
    let startedAt: Date
    let pausedAt: Date?
    let elapsedSecondsWhenPaused: Int?
    let totalDurationSeconds: Int?
    let linkedTaskId: UUID?
    let linkedPlanBlockId: UUID?

    enum TimerType: String, Codable {
        case stopwatch
        case countdown
        case pomodoro
    }
}

/// Data structure for persisting Pomodoro session state
struct PersistedPomodoroData: Codable {
    let sessionId: UUID
    let phase: PomodoroPhase
    let currentCycle: Int
    let totalCycles: Int
    let focusDurationMinutes: Int
    let shortBreakMinutes: Int
    let longBreakMinutes: Int
    let phaseStartedAt: Date
    let phaseDurationSeconds: Int
    let linkedTaskId: UUID?
    let linkedPlanBlockId: UUID?
}
