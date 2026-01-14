import Foundation

/// Use case for fetching daily plan items
@MainActor
final class FetchDailyPlanItemsUseCase {

    // MARK: - Dependencies

    private let repository: DailyPlanItemRepository

    // MARK: - Initialization

    init(repository: DailyPlanItemRepository) {
        self.repository = repository
    }

    // MARK: - Execute

    /// Fetch all items for a specific date
    func execute(for date: Date) throws -> [DailyPlanItemModel] {
        try repository.fetchItems(for: date)
    }

    /// Fetch incomplete items for a specific date
    func executeIncomplete(for date: Date) throws -> [DailyPlanItemModel] {
        try repository.fetchIncompleteItems(for: date)
    }

    /// Fetch completed items for a specific date
    func executeCompleted(for date: Date) throws -> [DailyPlanItemModel] {
        try repository.fetchCompletedItems(for: date)
    }

    /// Fetch a specific item by ID
    func execute(id: UUID) throws -> DailyPlanItemModel? {
        try repository.fetch(id: id)
    }
}
