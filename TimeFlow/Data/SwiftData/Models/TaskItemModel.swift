import Foundation
import SwiftData

/// Status of a task
enum TaskStatus: String, Codable, CaseIterable {
    case todo = "todo"
    case done = "done"

    var displayName: String {
        switch self {
        case .todo: return "To Do"
        case .done: return "Done"
        }
    }

    var icon: String {
        switch self {
        case .todo: return "circle"
        case .done: return "checkmark.circle.fill"
        }
    }
}

/// SwiftData model for task items with estimated time
@Model
final class TaskItemModel {

    // MARK: - Properties

    @Attribute(.unique)
    var id: UUID

    /// Task title
    var title: String

    /// Estimated time to complete (in minutes)
    var estimatedMinutes: Int

    /// Scheduled date (optional - nil means not scheduled)
    var scheduledDate: Date?

    /// Task status (stored as String for SwiftData compatibility)
    var statusRaw: String

    /// The current status of the task
    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .todo }
        set { statusRaw = newValue.rawValue }
    }

    /// Optional notes
    var notes: String?

    /// Priority level (0 = normal, 1 = high, 2 = urgent)
    var priority: Int

    /// Created timestamp
    var createdAt: Date

    /// Completed timestamp (nil if not completed)
    var completedAt: Date?

    /// Sort order within the list
    var sortOrder: Int

    // MARK: - Computed Properties

    /// Check if task is scheduled for today
    var isScheduledForToday: Bool {
        guard let scheduled = scheduledDate else { return false }
        return Calendar.current.isDateInToday(scheduled)
    }

    /// Check if task is overdue
    var isOverdue: Bool {
        guard let scheduled = scheduledDate, status == .todo else { return false }
        return scheduled < Calendar.current.startOfDay(for: Date())
    }

    /// Check if task is completed
    var isCompleted: Bool {
        status == .done
    }

    /// Formatted estimated time
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
        title: String,
        estimatedMinutes: Int,
        scheduledDate: Date? = nil,
        status: TaskStatus = .todo,
        notes: String? = nil,
        priority: Int = 0,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.estimatedMinutes = estimatedMinutes
        self.scheduledDate = scheduledDate
        self.statusRaw = status.rawValue
        self.notes = notes
        self.priority = priority
        self.createdAt = Date()
        self.completedAt = nil
        self.sortOrder = sortOrder
    }

    // MARK: - Methods

    /// Mark task as completed
    func markCompleted() {
        status = .done
        completedAt = Date()
    }

    /// Mark task as not completed
    func markIncomplete() {
        status = .todo
        completedAt = nil
    }
}

// MARK: - Identifiable

extension TaskItemModel: Identifiable {}

// MARK: - Hashable

extension TaskItemModel: Hashable {
    static func == (lhs: TaskItemModel, rhs: TaskItemModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
