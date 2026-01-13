import Foundation
import SwiftData

/// SwiftData model for planned time blocks
@Model
final class PlanBlockModel {

    // MARK: - Properties

    @Attribute(.unique)
    var id: UUID

    /// The date this block is scheduled for (normalized to start of day)
    var date: Date

    /// Start time of the block
    var startAt: Date

    /// End time of the block
    var endAt: Date

    /// Title of the block
    var title: String

    /// Optional notes or description
    var note: String?

    /// Optional category ID for grouping/coloring
    var categoryId: UUID?

    /// Whether this block is fixed (cannot be moved by auto-scheduling)
    var isFixed: Bool

    /// Created timestamp
    var createdAt: Date

    /// Last modified timestamp
    var updatedAt: Date

    // MARK: - Computed Properties

    /// Duration in minutes
    var durationMinutes: Int {
        Int(endAt.timeIntervalSince(startAt) / 60)
    }

    /// Time slot representation
    var timeSlot: TimeSlot {
        TimeSlot(startAt: startAt, endAt: endAt)
    }

    /// Check if the block is valid
    var isValid: Bool {
        endAt > startAt
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        date: Date,
        startAt: Date,
        endAt: Date,
        title: String,
        note: String? = nil,
        categoryId: UUID? = nil,
        isFixed: Bool = false
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.startAt = startAt
        self.endAt = endAt
        self.title = title
        self.note = note
        self.categoryId = categoryId
        self.isFixed = isFixed
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Identifiable

extension PlanBlockModel: Identifiable {}

// MARK: - Hashable

extension PlanBlockModel: Hashable {
    static func == (lhs: PlanBlockModel, rhs: PlanBlockModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
