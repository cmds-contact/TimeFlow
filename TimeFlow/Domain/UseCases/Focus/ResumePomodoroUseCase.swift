import Foundation

/// Use case for resuming a paused Pomodoro session
@MainActor
final class ResumePomodoroUseCase {

    // MARK: - Dependencies

    private let timerService: TimerService

    // MARK: - Initialization

    init(timerService: TimerService) {
        self.timerService = timerService
    }

    // MARK: - Execute

    func execute() {
        timerService.resumePomodoro()
    }
}
