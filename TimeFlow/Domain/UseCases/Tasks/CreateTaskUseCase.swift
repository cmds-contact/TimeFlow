import Foundation

/// Use case for creating a new task
@MainActor
final class CreateTaskUseCase {

    // MARK: - Dependencies

    private let repository: TaskRepository

    // MARK: - Initialization

    init(repository: TaskRepository) {
        self.repository = repository
    }

    // MARK: - Execute

    func execute(
        title: String,
        estimatedMinutes: Int,
        scheduledDate: Date? = nil,
        notes: String? = nil,
        priority: Int = 0
    ) throws -> TaskItemModel {
        try repository.create(
            title: title,
            estimatedMinutes: estimatedMinutes,
            scheduledDate: scheduledDate,
            notes: notes,
            priority: priority
        )
    }
}
