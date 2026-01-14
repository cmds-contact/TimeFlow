import Foundation

/// Use case for deleting a daily plan item
@MainActor
final class DeleteDailyPlanItemUseCase {

    // MARK: - Dependencies

    private let repository: DailyPlanItemRepository

    // MARK: - Initialization

    init(repository: DailyPlanItemRepository) {
        self.repository = repository
    }

    // MARK: - Execute

    func execute(id: UUID) throws {
        try repository.delete(id: id)
    }

    func execute(_ item: DailyPlanItemModel) throws {
        try repository.delete(item)
    }
}
