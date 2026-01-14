import Foundation
import SwiftData

/// Repository for DailyPlanItem CRUD operations
@MainActor
final class DailyPlanItemRepository {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    /// Create a new daily plan item
    func create(
        date: Date,
        title: String,
        estimatedMinutes: Int
    ) throws -> DailyPlanItemModel {
        // Get the next sort order for this date
        let existingItems = try fetchItems(for: date)
        let maxSortOrder = existingItems.map(\.sortOrder).max() ?? -1

        let item = DailyPlanItemModel(
            date: date,
            title: title,
            estimatedMinutes: estimatedMinutes,
            sortOrder: maxSortOrder + 1
        )

        modelContext.insert(item)
        try modelContext.save()

        return item
    }

    // MARK: - Read

    /// Fetch all items for a specific date
    func fetchItems(for date: Date) throws -> [DailyPlanItemModel] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        let predicate = #Predicate<DailyPlanItemModel> { item in
            item.date >= startOfDay && item.date < endOfDay
        }

        let descriptor = FetchDescriptor<DailyPlanItemModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Fetch incomplete items for a specific date
    func fetchIncompleteItems(for date: Date) throws -> [DailyPlanItemModel] {
        let items = try fetchItems(for: date)
        return items.filter { !$0.isCompleted }
    }

    /// Fetch completed items for a specific date
    func fetchCompletedItems(for date: Date) throws -> [DailyPlanItemModel] {
        let items = try fetchItems(for: date)
        return items.filter { $0.isCompleted }
    }

    /// Fetch a specific item by ID
    func fetch(id: UUID) throws -> DailyPlanItemModel? {
        let predicate = #Predicate<DailyPlanItemModel> { item in
            item.id == id
        }

        let descriptor = FetchDescriptor<DailyPlanItemModel>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    /// Fetch all items
    func fetchAll() throws -> [DailyPlanItemModel] {
        let descriptor = FetchDescriptor<DailyPlanItemModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse), SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Update

    /// Update an existing item
    func update(_ item: DailyPlanItemModel) throws {
        item.updatedAt = Date()
        try modelContext.save()
    }

    /// Update item title and estimated time
    func update(id: UUID, title: String?, estimatedMinutes: Int?) throws {
        guard let item = try fetch(id: id) else { return }
        if let title = title {
            item.title = title
        }
        if let estimatedMinutes = estimatedMinutes {
            item.estimatedMinutes = estimatedMinutes
        }
        item.updatedAt = Date()
        try modelContext.save()
    }

    /// Toggle completion status
    func toggleCompletion(id: UUID) throws {
        guard let item = try fetch(id: id) else { return }
        item.toggleCompletion()
        try modelContext.save()
    }

    /// Mark item as completed
    func complete(id: UUID) throws {
        guard let item = try fetch(id: id) else { return }
        item.markCompleted()
        try modelContext.save()
    }

    /// Mark item as incomplete
    func uncomplete(id: UUID) throws {
        guard let item = try fetch(id: id) else { return }
        item.markIncomplete()
        try modelContext.save()
    }

    /// Update sort order for items (after reordering)
    func updateOrder(items: [DailyPlanItemModel]) throws {
        for (index, item) in items.enumerated() {
            item.sortOrder = index
            item.updatedAt = Date()
        }
        try modelContext.save()
    }

    // MARK: - Delete

    /// Delete an item
    func delete(_ item: DailyPlanItemModel) throws {
        modelContext.delete(item)
        try modelContext.save()
    }

    /// Delete an item by ID
    func delete(id: UUID) throws {
        guard let item = try fetch(id: id) else { return }
        modelContext.delete(item)
        try modelContext.save()
    }

    // MARK: - Statistics

    /// Get total estimated minutes for a date
    func totalEstimatedMinutes(for date: Date) throws -> Int {
        let items = try fetchItems(for: date)
        return items.reduce(0) { $0 + $1.estimatedMinutes }
    }

    /// Get total estimated minutes for incomplete items
    func incompleteEstimatedMinutes(for date: Date) throws -> Int {
        let items = try fetchIncompleteItems(for: date)
        return items.reduce(0) { $0 + $1.estimatedMinutes }
    }

    /// Get total estimated minutes for completed items
    func completedEstimatedMinutes(for date: Date) throws -> Int {
        let items = try fetchCompletedItems(for: date)
        return items.reduce(0) { $0 + $1.estimatedMinutes }
    }

    /// Get item count for a date
    func itemCount(for date: Date) throws -> Int {
        try fetchItems(for: date).count
    }

    /// Get completed item count for a date
    func completedCount(for date: Date) throws -> Int {
        try fetchCompletedItems(for: date).count
    }
}
