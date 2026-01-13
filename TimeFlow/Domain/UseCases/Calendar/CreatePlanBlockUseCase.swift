import Foundation

/// Use case for creating a new plan block
@MainActor
final class CreatePlanBlockUseCase {

    // MARK: - Dependencies

    private let repository: PlanBlockRepository
    private let timeCalculator: TimeCalculator

    // MARK: - Initialization

    init(repository: PlanBlockRepository, timeCalculator: TimeCalculator) {
        self.repository = repository
        self.timeCalculator = timeCalculator
    }

    // MARK: - Errors

    enum Error: Swift.Error, LocalizedError {
        case invalidTimeSlot
        case endBeforeStart
        case tooShort(minimumMinutes: Int)
        case overlapsWithExisting

        var errorDescription: String? {
            switch self {
            case .invalidTimeSlot:
                return "Invalid time slot"
            case .endBeforeStart:
                return "End time must be after start time"
            case .tooShort(let min):
                return "Block must be at least \(min) minutes"
            case .overlapsWithExisting:
                return "This time slot overlaps with an existing block"
            }
        }
    }

    // MARK: - Execute

    /// Create a new plan block
    /// - Parameters:
    ///   - date: The date for the block
    ///   - startAt: Start time
    ///   - endAt: End time
    ///   - title: Block title
    ///   - note: Optional notes
    ///   - categoryId: Optional category
    ///   - isFixed: Whether the block is fixed
    ///   - minimumMinutes: Minimum duration (default: 15)
    /// - Returns: The created plan block
    func execute(
        date: Date,
        startAt: Date,
        endAt: Date,
        title: String,
        note: String? = nil,
        categoryId: UUID? = nil,
        isFixed: Bool = false,
        minimumMinutes: Int = 15
    ) throws -> PlanBlockModel {
        // Validate time slot
        guard timeCalculator.isValidSlot(startAt: startAt, endAt: endAt) else {
            throw Error.endBeforeStart
        }

        let slot = TimeSlot(startAt: startAt, endAt: endAt)

        guard timeCalculator.hasMinimumDuration(slot: slot, minimumMinutes: minimumMinutes) else {
            throw Error.tooShort(minimumMinutes: minimumMinutes)
        }

        // Check for overlaps
        if try repository.hasOverlap(date: date, startAt: startAt, endAt: endAt) {
            throw Error.overlapsWithExisting
        }

        // Create the block
        return try repository.create(
            date: date,
            startAt: startAt,
            endAt: endAt,
            title: title,
            note: note,
            categoryId: categoryId,
            isFixed: isFixed
        )
    }
}
