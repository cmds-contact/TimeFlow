import Foundation

/// Use case for updating an existing plan block
@MainActor
final class UpdatePlanBlockUseCase {

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
        case blockNotFound
        case invalidTimeSlot
        case overlapsWithExisting

        var errorDescription: String? {
            switch self {
            case .blockNotFound:
                return "Plan block not found"
            case .invalidTimeSlot:
                return "Invalid time slot"
            case .overlapsWithExisting:
                return "This time slot overlaps with an existing block"
            }
        }
    }

    // MARK: - Execute

    /// Update a plan block's properties
    func execute(
        id: UUID,
        title: String? = nil,
        note: String? = nil,
        categoryId: UUID? = nil,
        isFixed: Bool? = nil
    ) throws {
        guard let block = try repository.fetch(id: id) else {
            throw Error.blockNotFound
        }

        if let title = title {
            block.title = title
        }

        if let note = note {
            block.note = note
        }

        if let categoryId = categoryId {
            block.categoryId = categoryId
        }

        if let isFixed = isFixed {
            block.isFixed = isFixed
        }

        try repository.update(block)
    }

    /// Move a plan block to new times
    func move(
        id: UUID,
        to startAt: Date,
        endAt: Date
    ) throws {
        guard let block = try repository.fetch(id: id) else {
            throw Error.blockNotFound
        }

        // Validate time slot
        guard timeCalculator.isValidSlot(startAt: startAt, endAt: endAt) else {
            throw Error.invalidTimeSlot
        }

        // Check for overlaps (excluding this block)
        if try repository.hasOverlap(date: block.date, startAt: startAt, endAt: endAt, excludingId: id) {
            throw Error.overlapsWithExisting
        }

        try repository.updateTimes(id: id, startAt: startAt, endAt: endAt)
    }

    /// Resize a plan block (change duration)
    func resize(
        id: UUID,
        newStartAt: Date? = nil,
        newEndAt: Date? = nil
    ) throws {
        guard let block = try repository.fetch(id: id) else {
            throw Error.blockNotFound
        }

        let startAt = newStartAt ?? block.startAt
        let endAt = newEndAt ?? block.endAt

        // Validate time slot
        guard timeCalculator.isValidSlot(startAt: startAt, endAt: endAt) else {
            throw Error.invalidTimeSlot
        }

        // Check for overlaps
        if try repository.hasOverlap(date: block.date, startAt: startAt, endAt: endAt, excludingId: id) {
            throw Error.overlapsWithExisting
        }

        try repository.updateTimes(id: id, startAt: startAt, endAt: endAt)
    }
}
