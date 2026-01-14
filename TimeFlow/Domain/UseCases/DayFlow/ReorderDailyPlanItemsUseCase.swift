import Foundation

/// Use case for reordering daily plan items
@MainActor
final class ReorderDailyPlanItemsUseCase {

    // MARK: - Dependencies

    private let repository: DailyPlanItemRepository

    // MARK: - Initialization

    init(repository: DailyPlanItemRepository) {
        self.repository = repository
    }

    // MARK: - Execute

    /// Update sort order for all items in the list
    func execute(items: [DailyPlanItemModel]) throws {
        try repository.updateOrder(items: items)
    }

    /// Move item from source index to destination index
    func execute(items: inout [DailyPlanItemModel], from source: IndexSet, to destination: Int) throws {
        items.move(fromOffsets: source, toOffset: destination)
        try repository.updateOrder(items: items)
    }
}
