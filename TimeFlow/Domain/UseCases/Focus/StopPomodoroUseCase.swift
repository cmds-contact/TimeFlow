import Foundation

/// Use case for stopping a Pomodoro session
@MainActor
final class StopPomodoroUseCase {

    // MARK: - Dependencies

    private let repository: PomodoroRepository
    private let timerService: TimerService

    // MARK: - Initialization

    init(repository: PomodoroRepository, timerService: TimerService) {
        self.repository = repository
        self.timerService = timerService
    }

    // MARK: - Execute

    func execute() async throws {
        // Stop the timer (this will create ActualBlocks for completed focus sessions)
        try await timerService.stopPomodoro()

        // Complete the active session in the repository
        if let activeSession = try repository.fetchActiveSession() {
            try repository.complete(id: activeSession.id)
        }
    }
}
