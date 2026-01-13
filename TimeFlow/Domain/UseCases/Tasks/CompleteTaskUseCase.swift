import Foundation

/// Use case for completing/uncompleting a task
@MainActor
final class CompleteTaskUseCase {

    // MARK: - Dependencies

    private let repository: TaskRepository

    // MARK: - Initialization

    init(repository: TaskRepository) {
        self.repository = repository
    }

    // MARK: - Execute

    /// Mark a task as completed
    func complete(id: UUID) throws {
        try repository.complete(id: id)
    }

    /// Mark a task as incomplete
    func uncomplete(id: UUID) throws {
        try repository.uncomplete(id: id)
    }

    /// Toggle task completion status
    func toggle(id: UUID) throws {
        guard let task = try repository.fetch(id: id) else { return }

        if task.isCompleted {
            try repository.uncomplete(id: id)
        } else {
            try repository.complete(id: id)
        }
    }
}
