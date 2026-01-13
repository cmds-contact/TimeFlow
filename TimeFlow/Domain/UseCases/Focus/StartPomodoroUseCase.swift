import Foundation

/// Use case for starting a Pomodoro session
@MainActor
final class StartPomodoroUseCase {

    // MARK: - Dependencies

    private let repository: PomodoroRepository
    private let timerService: TimerService
    private let settings: UserSettings

    // MARK: - Initialization

    init(
        repository: PomodoroRepository,
        timerService: TimerService,
        settings: UserSettings
    ) {
        self.repository = repository
        self.timerService = timerService
        self.settings = settings
    }

    // MARK: - Execute

    /// Start a new Pomodoro session with default settings
    func execute(
        linkedTaskId: UUID? = nil,
        linkedPlanBlockId: UUID? = nil
    ) throws -> PomodoroSessionModel {
        // Create session record
        let session = try repository.create(
            focusMinutes: settings.focusDuration,
            breakMinutes: settings.shortBreakDuration,
            longBreakMinutes: settings.longBreakDuration,
            targetCycles: settings.cyclesBeforeLongBreak,
            linkedTaskId: linkedTaskId,
            linkedPlanBlockId: linkedPlanBlockId
        )

        // Start the timer
        timerService.startPomodoro(
            focusMinutes: settings.focusDuration,
            shortBreakMinutes: settings.shortBreakDuration,
            longBreakMinutes: settings.longBreakDuration,
            cycles: settings.cyclesBeforeLongBreak,
            linkedTaskId: linkedTaskId,
            linkedPlanBlockId: linkedPlanBlockId
        )

        return session
    }

    /// Start with custom settings
    func execute(
        focusMinutes: Int,
        shortBreakMinutes: Int,
        longBreakMinutes: Int,
        cycles: Int,
        linkedTaskId: UUID? = nil,
        linkedPlanBlockId: UUID? = nil
    ) throws -> PomodoroSessionModel {
        let session = try repository.create(
            focusMinutes: focusMinutes,
            breakMinutes: shortBreakMinutes,
            longBreakMinutes: longBreakMinutes,
            targetCycles: cycles,
            linkedTaskId: linkedTaskId,
            linkedPlanBlockId: linkedPlanBlockId
        )

        timerService.startPomodoro(
            focusMinutes: focusMinutes,
            shortBreakMinutes: shortBreakMinutes,
            longBreakMinutes: longBreakMinutes,
            cycles: cycles,
            linkedTaskId: linkedTaskId,
            linkedPlanBlockId: linkedPlanBlockId
        )

        return session
    }
}
