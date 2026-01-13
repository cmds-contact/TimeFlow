import Foundation
import SwiftData

/// Repository for ActualBlock CRUD operations
@MainActor
final class ActualBlockRepository {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    /// Create a new actual block
    func create(
        startAt: Date,
        endAt: Date,
        title: String? = nil,
        source: RecordSource,
        linkedPlanBlockId: UUID? = nil
    ) throws -> ActualBlockModel {
        let block = ActualBlockModel(
            startAt: startAt,
            endAt: endAt,
            title: title,
            source: source,
            linkedPlanBlockId: linkedPlanBlockId
        )

        modelContext.insert(block)
        try modelContext.save()

        return block
    }

    // MARK: - Read

    /// Fetch all actual blocks for a specific date
    func fetchBlocks(for date: Date) throws -> [ActualBlockModel] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        let predicate = #Predicate<ActualBlockModel> { block in
            block.startAt >= startOfDay && block.startAt < endOfDay
        }

        let descriptor = FetchDescriptor<ActualBlockModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startAt)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Fetch all actual blocks for a date range
    func fetchBlocks(from startDate: Date, to endDate: Date) throws -> [ActualBlockModel] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) ?? endDate

        let predicate = #Predicate<ActualBlockModel> { block in
            block.startAt >= start && block.startAt < end
        }

        let descriptor = FetchDescriptor<ActualBlockModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startAt)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Fetch a specific actual block by ID
    func fetch(id: UUID) throws -> ActualBlockModel? {
        let predicate = #Predicate<ActualBlockModel> { block in
            block.id == id
        }

        let descriptor = FetchDescriptor<ActualBlockModel>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    /// Fetch actual blocks linked to a specific plan block
    func fetchLinked(toPlanBlockId planBlockId: UUID) throws -> [ActualBlockModel] {
        let predicate = #Predicate<ActualBlockModel> { block in
            block.linkedPlanBlockId == planBlockId
        }

        let descriptor = FetchDescriptor<ActualBlockModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startAt)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Fetch all actual blocks
    func fetchAll() throws -> [ActualBlockModel] {
        let descriptor = FetchDescriptor<ActualBlockModel>(
            sortBy: [SortDescriptor(\.startAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Update

    /// Update an existing actual block
    func update(_ block: ActualBlockModel) throws {
        try modelContext.save()
    }

    /// Link an actual block to a plan block
    func linkToPlan(actualBlockId: UUID, planBlockId: UUID) throws {
        guard let block = try fetch(id: actualBlockId) else { return }
        block.linkedPlanBlockId = planBlockId
        try modelContext.save()
    }

    /// Unlink an actual block from its plan block
    func unlinkFromPlan(actualBlockId: UUID) throws {
        guard let block = try fetch(id: actualBlockId) else { return }
        block.linkedPlanBlockId = nil
        try modelContext.save()
    }

    // MARK: - Delete

    /// Delete an actual block
    func delete(_ block: ActualBlockModel) throws {
        modelContext.delete(block)
        try modelContext.save()
    }

    /// Delete an actual block by ID
    func delete(id: UUID) throws {
        guard let block = try fetch(id: id) else { return }
        modelContext.delete(block)
        try modelContext.save()
    }

    // MARK: - Statistics

    /// Get total tracked time for a date (in minutes)
    func totalTrackedMinutes(for date: Date) throws -> Int {
        let blocks = try fetchBlocks(for: date)
        return blocks.reduce(0) { $0 + $1.durationMinutes }
    }

    /// Get tracked time by source for a date
    func trackedMinutesBySource(for date: Date) throws -> [RecordSource: Int] {
        let blocks = try fetchBlocks(for: date)
        var result: [RecordSource: Int] = [:]

        for block in blocks {
            result[block.source, default: 0] += block.durationMinutes
        }

        return result
    }
}
