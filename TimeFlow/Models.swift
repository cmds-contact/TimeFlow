import Foundation
import SwiftData

/// Time block recording model
@Model
final class TimeBlock {
    @Attribute(.unique) var id: UUID
    var startAt: Date
    var endAt: Date
    var title: String
    var source: String  // "manual" | "timer"
    var createdAt: Date

    init(
        id: UUID = UUID(),
        startAt: Date,
        endAt: Date,
        title: String = "",
        source: String = "manual"
    ) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.title = title
        self.source = source
        self.createdAt = Date()
    }

    /// Duration in minutes
    var durationMinutes: Int {
        Int(endAt.timeIntervalSince(startAt) / 60)
    }

    /// TimeSlot representation
    var timeSlot: TimeSlot {
        TimeSlot(startAt: startAt, endAt: endAt)
    }

    /// Check if valid (end > start)
    var isValid: Bool {
        endAt > startAt
    }
}

// MARK: - Source Type

extension TimeBlock {
    static let sourceManual = "manual"
    static let sourceTimer = "timer"
}
