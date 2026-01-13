import Foundation

/// Use case for creating actual blocks manually
@MainActor
final class CreateActualBlockUseCase {

    // MARK: - Dependencies

    private let repository: ActualBlockRepository
    private let timeCalculator: TimeCalculator

    // MARK: - Initialization

    init(repository: ActualBlockRepository, timeCalculator: TimeCalculator) {
        self.repository = repository
        self.timeCalculator = timeCalculator
    }

    // MARK: - Errors

    enum Error: Swift.Error, LocalizedError {
        case invalidTimeSlot
        case endBeforeStart

        var errorDescription: String? {
            switch self {
            case .invalidTimeSlot:
                return "Invalid time slot"
            case .endBeforeStart:
                return "End time must be after start time"
            }
        }
    }

    // MARK: - Execute

    /// Create a new actual block manually
    func execute(
        startAt: Date,
        endAt: Date,
        title: String? = nil,
        linkedPlanBlockId: UUID? = nil
    ) throws -> ActualBlockModel {
        // Validate time slot
        guard timeCalculator.isValidSlot(startAt: startAt, endAt: endAt) else {
            throw Error.endBeforeStart
        }

        return try repository.create(
            startAt: startAt,
            endAt: endAt,
            title: title,
            source: .manual,
            linkedPlanBlockId: linkedPlanBlockId
        )
    }
}
