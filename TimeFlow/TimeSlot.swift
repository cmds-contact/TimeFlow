import Foundation

/// Represents a time slot with start and end times
struct TimeSlot: Equatable, Hashable, Codable, Sendable {

    // MARK: - Properties

    let startAt: Date
    let endAt: Date

    /// Duration in seconds
    var duration: TimeInterval {
        endAt.timeIntervalSince(startAt)
    }

    /// Duration in minutes
    var durationMinutes: Int {
        Int(duration / 60)
    }

    /// Check if the time slot is valid (end > start)
    var isValid: Bool {
        endAt > startAt
    }

    // MARK: - Initialization

    init(startAt: Date, endAt: Date) {
        self.startAt = startAt
        self.endAt = endAt
    }

    /// Create a time slot from start time and duration in minutes
    init(startAt: Date, durationMinutes: Int) {
        self.startAt = startAt
        self.endAt = startAt.addingTimeInterval(Double(durationMinutes) * 60)
    }

    /// Create a time slot for a specific date with hour/minute components
    init(date: Date, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        let calendar = Calendar.current
        let startComponents = DateComponents(hour: startHour, minute: startMinute)
        let endComponents = DateComponents(hour: endHour, minute: endMinute)

        let startOfDay = calendar.startOfDay(for: date)
        self.startAt = calendar.date(byAdding: startComponents, to: startOfDay) ?? date
        self.endAt = calendar.date(byAdding: endComponents, to: startOfDay) ?? date
    }

    // MARK: - Methods

    /// Check if this slot overlaps with another slot
    func overlaps(with other: TimeSlot) -> Bool {
        return startAt < other.endAt && other.startAt < endAt
    }

    /// Check if this slot contains a specific date
    func contains(_ date: Date) -> Bool {
        date >= startAt && date <= endAt
    }

    /// Round start and end times to the nearest interval (in minutes)
    func rounded(toMinutes interval: Int) -> TimeSlot {
        let intervalSeconds = Double(interval * 60)

        let roundedStart = Date(
            timeIntervalSinceReferenceDate: (startAt.timeIntervalSinceReferenceDate / intervalSeconds).rounded() * intervalSeconds
        )
        let roundedEnd = Date(
            timeIntervalSinceReferenceDate: (endAt.timeIntervalSinceReferenceDate / intervalSeconds).rounded() * intervalSeconds
        )

        return TimeSlot(startAt: roundedStart, endAt: roundedEnd)
    }
}

// MARK: - Comparable

extension TimeSlot: Comparable {
    static func < (lhs: TimeSlot, rhs: TimeSlot) -> Bool {
        if lhs.startAt == rhs.startAt {
            return lhs.endAt < rhs.endAt
        }
        return lhs.startAt < rhs.startAt
    }
}
