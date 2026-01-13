import Foundation
import SwiftData

/// Repository for TaskItem CRUD operations
@MainActor
final class TaskRepository {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    /// Create a new task
    func create(
        title: String,
        estimatedMinutes: Int,
        scheduledDate: Date? = nil,
        notes: String? = nil,
        priority: Int = 0
    ) throws -> TaskItemModel {
        // Get the next sort order
        let allTasks = try fetchAll()
        let maxSortOrder = allTasks.map(\.sortOrder).max() ?? 0

        let task = TaskItemModel(
            title: title,
            estimatedMinutes: estimatedMinutes,
            scheduledDate: scheduledDate,
            notes: notes,
            priority: priority,
            sortOrder: maxSortOrder + 1
        )

        modelContext.insert(task)
        try modelContext.save()

        return task
    }

    // MARK: - Read

    /// Fetch all tasks for a specific date
    func fetchTasks(for date: Date) throws -> [TaskItemModel] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        // Fetch all tasks with a scheduled date and filter in memory
        // (SwiftData doesn't support forced unwrap in predicates)
        let predicate = #Predicate<TaskItemModel> { task in
            task.scheduledDate != nil
        }

        let descriptor = FetchDescriptor<TaskItemModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.priority, order: .reverse), SortDescriptor(\.sortOrder)]
        )

        let allScheduledTasks = try modelContext.fetch(descriptor)
        return allScheduledTasks.filter { task in
            guard let scheduled = task.scheduledDate else { return false }
            return scheduled >= startOfDay && scheduled < endOfDay
        }
    }

    /// Fetch tasks for a date with specific status
    func fetchTasks(for date: Date, status: TaskStatus) throws -> [TaskItemModel] {
        let tasks = try fetchTasks(for: date)
        return tasks.filter { $0.status == status }
    }

    /// Fetch all incomplete tasks
    func fetchIncompleteTasks() throws -> [TaskItemModel] {
        let predicate = #Predicate<TaskItemModel> { task in
            task.statusRaw == "todo"
        }

        let descriptor = FetchDescriptor<TaskItemModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.priority, order: .reverse), SortDescriptor(\.sortOrder)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Fetch all overdue tasks
    func fetchOverdueTasks() throws -> [TaskItemModel] {
        let today = Calendar.current.startOfDay(for: Date())

        // Fetch incomplete tasks with a scheduled date and filter in memory
        // (SwiftData doesn't support forced unwrap in predicates)
        let predicate = #Predicate<TaskItemModel> { task in
            task.statusRaw == "todo" &&
            task.scheduledDate != nil
        }

        let descriptor = FetchDescriptor<TaskItemModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.scheduledDate)]
        )

        let incompleteTasks = try modelContext.fetch(descriptor)
        return incompleteTasks.filter { task in
            guard let scheduled = task.scheduledDate else { return false }
            return scheduled < today
        }
    }

    /// Fetch a specific task by ID
    func fetch(id: UUID) throws -> TaskItemModel? {
        let predicate = #Predicate<TaskItemModel> { task in
            task.id == id
        }

        let descriptor = FetchDescriptor<TaskItemModel>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    /// Fetch all tasks
    func fetchAll() throws -> [TaskItemModel] {
        let descriptor = FetchDescriptor<TaskItemModel>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch unscheduled tasks
    func fetchUnscheduledTasks() throws -> [TaskItemModel] {
        let predicate = #Predicate<TaskItemModel> { task in
            task.scheduledDate == nil && task.statusRaw == "todo"
        }

        let descriptor = FetchDescriptor<TaskItemModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.priority, order: .reverse), SortDescriptor(\.sortOrder)]
        )

        return try modelContext.fetch(descriptor)
    }

    // MARK: - Update

    /// Update an existing task
    func update(_ task: TaskItemModel) throws {
        try modelContext.save()
    }

    /// Mark a task as completed
    func complete(id: UUID) throws {
        guard let task = try fetch(id: id) else { return }
        task.markCompleted()
        try modelContext.save()
    }

    /// Mark a task as incomplete
    func uncomplete(id: UUID) throws {
        guard let task = try fetch(id: id) else { return }
        task.markIncomplete()
        try modelContext.save()
    }

    /// Schedule a task for a specific date
    func schedule(id: UUID, for date: Date) throws {
        guard let task = try fetch(id: id) else { return }
        task.scheduledDate = date
        try modelContext.save()
    }

    /// Unschedule a task
    func unschedule(id: UUID) throws {
        guard let task = try fetch(id: id) else { return }
        task.scheduledDate = nil
        try modelContext.save()
    }

    /// Update task order
    func updateOrder(tasks: [TaskItemModel]) throws {
        for (index, task) in tasks.enumerated() {
            task.sortOrder = index
        }
        try modelContext.save()
    }

    // MARK: - Delete

    /// Delete a task
    func delete(_ task: TaskItemModel) throws {
        modelContext.delete(task)
        try modelContext.save()
    }

    /// Delete a task by ID
    func delete(id: UUID) throws {
        guard let task = try fetch(id: id) else { return }
        modelContext.delete(task)
        try modelContext.save()
    }

    // MARK: - Statistics

    /// Get total estimated minutes for a date
    func totalEstimatedMinutes(for date: Date) throws -> Int {
        let tasks = try fetchTasks(for: date, status: .todo)
        return tasks.reduce(0) { $0 + $1.estimatedMinutes }
    }

    /// Get completed minutes for a date
    func completedMinutes(for date: Date) throws -> Int {
        let tasks = try fetchTasks(for: date, status: .done)
        return tasks.reduce(0) { $0 + $1.estimatedMinutes }
    }
}
