import Foundation

/// Use case for linking actual blocks to plan blocks
@MainActor
final class LinkActualToPlanUseCase {

    // MARK: - Dependencies

    private let actualRepository: ActualBlockRepository
    private let planRepository: PlanBlockRepository
    private let timeCalculator: TimeCalculator

    // MARK: - Initialization

    init(
        actualRepository: ActualBlockRepository,
        planRepository: PlanBlockRepository,
        timeCalculator: TimeCalculator
    ) {
        self.actualRepository = actualRepository
        self.planRepository = planRepository
        self.timeCalculator = timeCalculator
    }

    // MARK: - Errors

    enum Error: Swift.Error, LocalizedError {
        case actualBlockNotFound
        case planBlockNotFound
        case noTimeOverlap

        var errorDescription: String? {
            switch self {
            case .actualBlockNotFound:
                return "Actual block not found"
            case .planBlockNotFound:
                return "Plan block not found"
            case .noTimeOverlap:
                return "The actual time doesn't overlap with the planned time"
            }
        }
    }

    // MARK: - Execute

    /// Link an actual block to a plan block
    func execute(actualBlockId: UUID, planBlockId: UUID) throws {
        guard let actualBlock = try actualRepository.fetch(id: actualBlockId) else {
            throw Error.actualBlockNotFound
        }

        guard let planBlock = try planRepository.fetch(id: planBlockId) else {
            throw Error.planBlockNotFound
        }

        // Validate time overlap
        let actualSlot = actualBlock.timeSlot
        let planSlot = planBlock.timeSlot

        guard actualSlot.overlaps(with: planSlot) else {
            throw Error.noTimeOverlap
        }

        try actualRepository.linkToPlan(actualBlockId: actualBlockId, planBlockId: planBlockId)
    }

    /// Unlink an actual block from its plan block
    func unlink(actualBlockId: UUID) throws {
        try actualRepository.unlinkFromPlan(actualBlockId: actualBlockId)
    }

    /// Auto-link actual block to overlapping plan block
    func autoLink(actualBlockId: UUID) throws {
        guard let actualBlock = try actualRepository.fetch(id: actualBlockId) else {
            throw Error.actualBlockNotFound
        }

        // Find plan blocks for the same date
        let planBlocks = try planRepository.fetchBlocks(for: actualBlock.date)

        // Find the best matching plan block (most overlap)
        var bestMatch: (block: PlanBlockModel, overlap: TimeInterval)?

        for planBlock in planBlocks {
            if let intersection = actualBlock.timeSlot.intersection(with: planBlock.timeSlot) {
                if bestMatch == nil || intersection.duration > bestMatch!.overlap {
                    bestMatch = (planBlock, intersection.duration)
                }
            }
        }

        if let match = bestMatch {
            try actualRepository.linkToPlan(actualBlockId: actualBlockId, planBlockId: match.block.id)
        }
    }
}
