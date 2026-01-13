import Foundation

/// Use case for updating a task
@MainActor
final class UpdateTaskUseCase {

    // MARK: - Dependencies

    private let repository: TaskRepository

    // MARK: - Initialization

    init(repository: TaskRepository) {
        self.repository = repository
    }

    // MARK: - Errors

    enum Error: Swift.Error, LocalizedError {
        case taskNotFound

        var errorDescription: String? {
            switch self {
            case .taskNotFound:
                return "Task not found"
            }
        }
    }

    // MARK: - Execute

    func execute(
        id: UUID,
        title: String? = nil,
        estimatedMinutes: Int? = nil,
        scheduledDate: Date? = nil,
        notes: String? = nil,
        priority: Int? = nil
    ) throws {
        guard let task = try repository.fetch(id: id) else {
            throw Error.taskNotFound
        }

        if let title = title {
            task.title = title
        }

        if let estimatedMinutes = estimatedMinutes {
            task.estimatedMinutes = estimatedMinutes
        }

        if let scheduledDate = scheduledDate {
            task.scheduledDate = scheduledDate
        }

        if let notes = notes {
            task.notes = notes
        }

        if let priority = priority {
            task.priority = priority
        }

        try repository.update(task)
    }

    /// Schedule a task for a specific date
    func schedule(id: UUID, for date: Date) throws {
        try repository.schedule(id: id, for: date)
    }

    /// Unschedule a task
    func unschedule(id: UUID) throws {
        try repository.unschedule(id: id)
    }
}
