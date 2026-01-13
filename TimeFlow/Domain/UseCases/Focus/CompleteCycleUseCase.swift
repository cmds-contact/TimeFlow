import Foundation

/// Use case for handling cycle completion in Pomodoro
@MainActor
final class CompleteCycleUseCase {

    // MARK: - Dependencies

    private let repository: PomodoroRepository
    private let actualBlockRepository: ActualBlockRepository
    private let timerService: TimerService
    private let settings: UserSettings

    // MARK: - Initialization

    init(
        repository: PomodoroRepository,
        actualBlockRepository: ActualBlockRepository,
        timerService: TimerService,
        settings: UserSettings
    ) {
        self.repository = repository
        self.actualBlockRepository = actualBlockRepository
        self.timerService = timerService
        self.settings = settings
    }

    // MARK: - Execute

    /// Called when a focus cycle completes
    func execute(
        sessionId: UUID,
        focusStartedAt: Date,
        focusEndedAt: Date,
        linkedPlanBlockId: UUID?
    ) throws {
        // Create ActualBlock for the completed focus session
        _ = try actualBlockRepository.create(
            startAt: focusStartedAt,
            endAt: focusEndedAt,
            title: "Pomodoro Focus",
            source: .pomodoro,
            linkedPlanBlockId: linkedPlanBlockId
        )

        // Update session cycle count
        try repository.incrementCycle(id: sessionId)
    }
}
