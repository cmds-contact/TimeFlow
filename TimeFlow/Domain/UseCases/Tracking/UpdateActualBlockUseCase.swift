import Foundation

/// Use case for updating an actual block
@MainActor
final class UpdateActualBlockUseCase {

    // MARK: - Dependencies

    private let repository: ActualBlockRepository

    // MARK: - Initialization

    init(repository: ActualBlockRepository) {
        self.repository = repository
    }

    // MARK: - Execute

    /// Update an actual block's properties
    func execute(
        id: UUID,
        title: String?,
        startAt: Date,
        endAt: Date
    ) throws {
        guard let block = try repository.fetch(id: id) else {
            throw Error.blockNotFound
        }

        guard endAt > startAt else {
            throw Error.invalidTimeSlot
        }

        block.title = title
        block.startAt = startAt
        block.endAt = endAt

        try repository.update(block)
    }

    // MARK: - Errors

    enum Error: LocalizedError {
        case blockNotFound
        case invalidTimeSlot

        var errorDescription: String? {
            switch self {
            case .blockNotFound:
                return "Actual block not found"
            case .invalidTimeSlot:
                return "End time must be after start time"
            }
        }
    }
}
