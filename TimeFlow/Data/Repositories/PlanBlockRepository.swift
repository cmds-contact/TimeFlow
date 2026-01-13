import Foundation
import SwiftData

/// Repository for PlanBlock CRUD operations
@MainActor
final class PlanBlockRepository {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    /// Create a new plan block
    func create(
        date: Date,
        startAt: Date,
        endAt: Date,
        title: String,
        note: String? = nil,
        categoryId: UUID? = nil,
        isFixed: Bool = false
    ) throws -> PlanBlockModel {
        let block = PlanBlockModel(
            date: date,
            startAt: startAt,
            endAt: endAt,
            title: title,
            note: note,
            categoryId: categoryId,
            isFixed: isFixed
        )

        modelContext.insert(block)
        try modelContext.save()

        return block
    }

    // MARK: - Read

    /// Fetch all plan blocks for a specific date
    func fetchBlocks(for date: Date) throws -> [PlanBlockModel] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        let predicate = #Predicate<PlanBlockModel> { block in
            block.date >= startOfDay && block.date < endOfDay
        }

        let descriptor = FetchDescriptor<PlanBlockModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startAt)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Fetch all plan blocks for a date range
    func fetchBlocks(from startDate: Date, to endDate: Date) throws -> [PlanBlockModel] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) ?? endDate

        let predicate = #Predicate<PlanBlockModel> { block in
            block.date >= start && block.date < end
        }

        let descriptor = FetchDescriptor<PlanBlockModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date), SortDescriptor(\.startAt)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Fetch a specific plan block by ID
    func fetch(id: UUID) throws -> PlanBlockModel? {
        let predicate = #Predicate<PlanBlockModel> { block in
            block.id == id
        }

        let descriptor = FetchDescriptor<PlanBlockModel>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    /// Fetch all plan blocks
    func fetchAll() throws -> [PlanBlockModel] {
        let descriptor = FetchDescriptor<PlanBlockModel>(
            sortBy: [SortDescriptor(\.date), SortDescriptor(\.startAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Update

    /// Update an existing plan block
    func update(_ block: PlanBlockModel) throws {
        block.updatedAt = Date()
        try modelContext.save()
    }

    /// Update plan block times
    func updateTimes(id: UUID, startAt: Date, endAt: Date) throws {
        guard let block = try fetch(id: id) else { return }
        block.startAt = startAt
        block.endAt = endAt
        block.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Delete

    /// Delete a plan block
    func delete(_ block: PlanBlockModel) throws {
        modelContext.delete(block)
        try modelContext.save()
    }

    /// Delete a plan block by ID
    func delete(id: UUID) throws {
        guard let block = try fetch(id: id) else { return }
        modelContext.delete(block)
        try modelContext.save()
    }

    // MARK: - Queries

    /// Check if a time slot overlaps with existing blocks
    func hasOverlap(date: Date, startAt: Date, endAt: Date, excludingId: UUID? = nil) throws -> Bool {
        let blocks = try fetchBlocks(for: date)

        for block in blocks {
            if let excludeId = excludingId, block.id == excludeId {
                continue
            }

            // Check for overlap
            if startAt < block.endAt && endAt > block.startAt {
                return true
            }
        }

        return false
    }
}
