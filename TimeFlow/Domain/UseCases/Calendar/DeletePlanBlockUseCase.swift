import Foundation

/// Use case for deleting a plan block
@MainActor
final class DeletePlanBlockUseCase {

    // MARK: - Dependencies

    private let repository: PlanBlockRepository

    // MARK: - Initialization

    init(repository: PlanBlockRepository) {
        self.repository = repository
    }

    // MARK: - Execute

    /// Delete a plan block by ID
    func execute(id: UUID) throws {
        try repository.delete(id: id)
    }

    /// Delete a plan block
    func execute(_ block: PlanBlockModel) throws {
        try repository.delete(block)
    }
}
