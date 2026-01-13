import Foundation
import SwiftData

/// Source of the actual time recording
enum RecordSource: String, Codable, CaseIterable {
    case manual = "manual"
    case timer = "timer"
    case pomodoro = "pomodoro"

    var displayName: String {
        switch self {
        case .manual: return "Manual Entry"
        case .timer: return "Timer"
        case .pomodoro: return "Pomodoro"
        }
    }

    var icon: String {
        switch self {
        case .manual: return "pencil"
        case .timer: return "stopwatch"
        case .pomodoro: return "timer"
        }
    }
}

/// SwiftData model for actual recorded time blocks
@Model
final class ActualBlockModel {

    // MARK: - Properties

    @Attribute(.unique)
    var id: UUID

    /// Start time of the recorded block
    var startAt: Date

    /// End time of the recorded block
    var endAt: Date

    /// Optional title/description
    var title: String?

    /// How this block was recorded (stored as String for SwiftData compatibility)
    private var sourceRaw: String

    /// The source of this recording
    var source: RecordSource {
        get { RecordSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    /// Optional link to a PlanBlock this actual time relates to
    var linkedPlanBlockId: UUID?

    /// Created timestamp
    var createdAt: Date

    // MARK: - Computed Properties

    /// Duration in minutes
    var durationMinutes: Int {
        Int(endAt.timeIntervalSince(startAt) / 60)
    }

    /// Time slot representation
    var timeSlot: TimeSlot {
        TimeSlot(startAt: startAt, endAt: endAt)
    }

    /// The date this block belongs to (normalized to start of day)
    var date: Date {
        Calendar.current.startOfDay(for: startAt)
    }

    /// Check if the block is valid
    var isValid: Bool {
        endAt > startAt
    }

    /// Check if this block is linked to a plan
    var isLinked: Bool {
        linkedPlanBlockId != nil
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        startAt: Date,
        endAt: Date,
        title: String? = nil,
        source: RecordSource,
        linkedPlanBlockId: UUID? = nil
    ) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.title = title
        self.sourceRaw = source.rawValue
        self.linkedPlanBlockId = linkedPlanBlockId
        self.createdAt = Date()
    }
}

// MARK: - Identifiable

extension ActualBlockModel: Identifiable {}

// MARK: - Hashable

extension ActualBlockModel: Hashable {
    static func == (lhs: ActualBlockModel, rhs: ActualBlockModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
