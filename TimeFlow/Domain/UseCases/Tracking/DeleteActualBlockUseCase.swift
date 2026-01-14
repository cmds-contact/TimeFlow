import Foundation

/// Use case for deleting an actual block
@MainActor
final class DeleteActualBlockUseCase {

    // MARK: - Dependencies

    private let repository: ActualBlockRepository

    // MARK: - Initialization

    init(repository: ActualBlockRepository) {
        self.repository = repository
    }

    // MARK: - Execute

    /// Delete an actual block by ID
    func execute(id: UUID) throws {
        try repository.delete(id: id)
    }

    /// Delete an actual block
    func execute(_ block: ActualBlockModel) throws {
        try repository.delete(block)
    }
}
