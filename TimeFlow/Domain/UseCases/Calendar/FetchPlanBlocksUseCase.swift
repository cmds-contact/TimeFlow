import Foundation

/// Use case for fetching plan blocks
@MainActor
final class FetchPlanBlocksUseCase {

    // MARK: - Dependencies

    private let repository: PlanBlockRepository

    // MARK: - Initialization

    init(repository: PlanBlockRepository) {
        self.repository = repository
    }

    // MARK: - Execute

    /// Fetch all plan blocks for a specific date
    func execute(for date: Date) throws -> [PlanBlockModel] {
        try repository.fetchBlocks(for: date)
    }

    /// Fetch plan blocks for a date range
    func execute(from startDate: Date, to endDate: Date) throws -> [PlanBlockModel] {
        try repository.fetchBlocks(from: startDate, to: endDate)
    }

    /// Fetch a specific plan block by ID
    func execute(id: UUID) throws -> PlanBlockModel? {
        try repository.fetch(id: id)
    }

    /// Fetch all plan blocks
    func executeAll() throws -> [PlanBlockModel] {
        try repository.fetchAll()
    }
}
