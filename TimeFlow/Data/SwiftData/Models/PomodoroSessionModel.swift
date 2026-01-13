import Foundation
import SwiftData

/// SwiftData model for Pomodoro sessions
@Model
final class PomodoroSessionModel {

    // MARK: - Properties

    @Attribute(.unique)
    var id: UUID

    /// When the session started
    var startAt: Date

    /// When the session ended (nil if still in progress)
    var endAt: Date?

    /// Focus duration in minutes
    var focusMinutes: Int

    /// Short break duration in minutes
    var breakMinutes: Int

    /// Long break duration in minutes
    var longBreakMinutes: Int

    /// Number of completed cycles
    var completedCycles: Int

    /// Target number of cycles
    var targetCycles: Int

    /// Optional link to a task this session is for
    var linkedTaskId: UUID?

    /// Optional link to a plan block
    var linkedPlanBlockId: UUID?

    /// Created timestamp
    var createdAt: Date

    // MARK: - Computed Properties

    /// Check if session is completed
    var isCompleted: Bool {
        endAt != nil && completedCycles >= targetCycles
    }

    /// Check if session is in progress
    var isInProgress: Bool {
        endAt == nil
    }

    /// Total focus time in minutes
    var totalFocusMinutes: Int {
        completedCycles * focusMinutes
    }

    /// Total break time in minutes
    var totalBreakMinutes: Int {
        let shortBreaks = max(0, completedCycles - 1)
        let longBreaks = completedCycles / 4
        return (shortBreaks - longBreaks) * breakMinutes + longBreaks * longBreakMinutes
    }

    /// Total session duration in minutes
    var totalDurationMinutes: Int {
        if let end = endAt {
            return Int(end.timeIntervalSince(startAt) / 60)
        }
        return Int(Date().timeIntervalSince(startAt) / 60)
    }

    /// Progress percentage (0.0 - 1.0)
    var progressPercentage: Double {
        guard targetCycles > 0 else { return 0 }
        return Double(completedCycles) / Double(targetCycles)
    }

    /// The date this session belongs to (normalized to start of day)
    var date: Date {
        Calendar.current.startOfDay(for: startAt)
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        startAt: Date = Date(),
        endAt: Date? = nil,
        focusMinutes: Int = 25,
        breakMinutes: Int = 5,
        longBreakMinutes: Int = 15,
        completedCycles: Int = 0,
        targetCycles: Int = 4,
        linkedTaskId: UUID? = nil,
        linkedPlanBlockId: UUID? = nil
    ) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.focusMinutes = focusMinutes
        self.breakMinutes = breakMinutes
        self.longBreakMinutes = longBreakMinutes
        self.completedCycles = completedCycles
        self.targetCycles = targetCycles
        self.linkedTaskId = linkedTaskId
        self.linkedPlanBlockId = linkedPlanBlockId
        self.createdAt = Date()
    }

    // MARK: - Methods

    /// Complete the session
    func complete() {
        endAt = Date()
    }

    /// Increment completed cycles
    func incrementCycle() {
        completedCycles += 1
        if completedCycles >= targetCycles {
            complete()
        }
    }
}

// MARK: - Identifiable

extension PomodoroSessionModel: Identifiable {}

// MARK: - Hashable

extension PomodoroSessionModel: Hashable {
    static func == (lhs: PomodoroSessionModel, rhs: PomodoroSessionModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
