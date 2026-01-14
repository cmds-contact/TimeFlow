import Foundation

/// Use case for updating an existing daily plan item
@MainActor
final class UpdateDailyPlanItemUseCase {

    // MARK: - Dependencies

    private let repository: DailyPlanItemRepository

    // MARK: - Initialization

    init(repository: DailyPlanItemRepository) {
        self.repository = repository
    }

    // MARK: - Execute

    /// Update item title and/or estimated time
    func execute(
        id: UUID,
        title: String? = nil,
        estimatedMinutes: Int? = nil
    ) throws {
        try repository.update(id: id, title: title, estimatedMinutes: estimatedMinutes)
    }

    /// Toggle completion status
    func toggleCompletion(id: UUID) throws {
        try repository.toggleCompletion(id: id)
    }

    /// Mark as completed
    func complete(id: UUID) throws {
        try repository.complete(id: id)
    }

    /// Mark as incomplete
    func uncomplete(id: UUID) throws {
        try repository.uncomplete(id: id)
    }
}
