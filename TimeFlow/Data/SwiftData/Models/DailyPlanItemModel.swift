import Foundation
import SwiftData

/// SwiftData model for daily plan items (independent task list per day)
/// Used in the Plan page to track what needs to be done and estimated time
@Model
final class DailyPlanItemModel {

    // MARK: - Properties

    @Attribute(.unique)
    var id: UUID

    /// The date this item is scheduled for (normalized to start of day)
    var date: Date

    /// Title of the plan item
    var title: String

    /// Estimated time in minutes
    var estimatedMinutes: Int

    /// Sort order within the day
    var sortOrder: Int

    /// Whether this item is completed
    var isCompleted: Bool

    /// Created timestamp
    var createdAt: Date

    /// Updated timestamp
    var updatedAt: Date

    // MARK: - Computed Properties

    /// Formatted estimated time string (e.g., "30m", "1h", "1h 30m")
    var estimatedTimeString: String {
        if estimatedMinutes < 60 {
            return "\(estimatedMinutes)m"
        }
        let hours = estimatedMinutes / 60
        let minutes = estimatedMinutes % 60
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        date: Date,
        title: String,
        estimatedMinutes: Int,
        sortOrder: Int = 0,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.title = title
        self.estimatedMinutes = estimatedMinutes
        self.sortOrder = sortOrder
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    /// Mark item as completed
    func markCompleted() {
        isCompleted = true
        updatedAt = Date()
    }

    /// Mark item as not completed
    func markIncomplete() {
        isCompleted = false
        updatedAt = Date()
    }

    /// Toggle completion status
    func toggleCompletion() {
        isCompleted.toggle()
        updatedAt = Date()
    }
}

// MARK: - Identifiable

extension DailyPlanItemModel: Identifiable {}

// MARK: - Hashable

extension DailyPlanItemModel: Hashable {
    static func == (lhs: DailyPlanItemModel, rhs: DailyPlanItemModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
