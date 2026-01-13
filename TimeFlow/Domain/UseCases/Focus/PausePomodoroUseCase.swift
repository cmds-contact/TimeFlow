import Foundation

/// Use case for pausing a Pomodoro session
@MainActor
final class PausePomodoroUseCase {

    // MARK: - Dependencies

    private let timerService: TimerService

    // MARK: - Initialization

    init(timerService: TimerService) {
        self.timerService = timerService
    }

    // MARK: - Execute

    func execute() {
        timerService.pausePomodoro()
    }
}
