import Foundation

/// Use case for starting manual time tracking
@MainActor
final class StartTrackingUseCase {

    // MARK: - Dependencies

    private let timerService: TimerService

    // MARK: - Initialization

    init(timerService: TimerService) {
        self.timerService = timerService
    }

    // MARK: - Execute

    /// Start tracking time
    /// - Parameters:
    ///   - linkedTaskId: Optional task to link this tracking to
    ///   - linkedPlanBlockId: Optional plan block to link this tracking to
    func execute(
        linkedTaskId: UUID? = nil,
        linkedPlanBlockId: UUID? = nil
    ) {
        timerService.startManualTimer(
            linkedTaskId: linkedTaskId,
            linkedPlanBlockId: linkedPlanBlockId
        )
    }
}
