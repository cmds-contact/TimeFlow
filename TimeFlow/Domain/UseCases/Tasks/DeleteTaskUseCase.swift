import Foundation

/// Use case for deleting a task
@MainActor
final class DeleteTaskUseCase {

    // MARK: - Dependencies

    private let repository: TaskRepository

    // MARK: - Initialization

    init(repository: TaskRepository) {
        self.repository = repository
    }

    // MARK: - Execute

    func execute(id: UUID) throws {
        try repository.delete(id: id)
    }

    func execute(_ task: TaskItemModel) throws {
        try repository.delete(task)
    }
}
