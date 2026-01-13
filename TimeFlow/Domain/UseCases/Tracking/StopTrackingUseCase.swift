import Foundation

/// Use case for stopping manual time tracking
@MainActor
final class StopTrackingUseCase {

    // MARK: - Dependencies

    private let timerService: TimerService
    private let repository: ActualBlockRepository

    // MARK: - Initialization

    init(timerService: TimerService, repository: ActualBlockRepository) {
        self.timerService = timerService
        self.repository = repository
    }

    // MARK: - Execute

    /// Stop tracking and create an actual block
    /// - Returns: The created actual block, or nil if timer wasn't running
    func execute() async throws -> ActualBlockModel? {
        try await timerService.stopManualTimer()
    }
}
