import Foundation

/// Use case for creating a new daily plan item
@MainActor
final class CreateDailyPlanItemUseCase {

    // MARK: - Dependencies

    private let repository: DailyPlanItemRepository

    // MARK: - Initialization

    init(repository: DailyPlanItemRepository) {
        self.repository = repository
    }

    // MARK: - Execute

    func execute(
        date: Date,
        title: String,
        estimatedMinutes: Int
    ) throws -> DailyPlanItemModel {
        try repository.create(
            date: date,
            title: title,
            estimatedMinutes: estimatedMinutes
        )
    }
}
