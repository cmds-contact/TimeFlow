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

    /// Duration in hours (as decimal)
    var durationHours: Double {
        duration / 3600
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
        // Two slots overlap if neither ends before the other starts
        return startAt < other.endAt && other.startAt < endAt
    }

    /// Check if this slot contains a specific date
    func contains(_ date: Date) -> Bool {
        date >= startAt && date <= endAt
    }

    /// Check if this slot completely contains another slot
    func contains(_ other: TimeSlot) -> Bool {
        startAt <= other.startAt && endAt >= other.endAt
    }

    /// Get the intersection of two time slots, if they overlap
    func intersection(with other: TimeSlot) -> TimeSlot? {
        guard overlaps(with: other) else { return nil }

        let intersectionStart = max(startAt, other.startAt)
        let intersectionEnd = min(endAt, other.endAt)

        return TimeSlot(startAt: intersectionStart, endAt: intersectionEnd)
    }

    /// Move the slot by a given time interval
    func moved(by interval: TimeInterval) -> TimeSlot {
        TimeSlot(
            startAt: startAt.addingTimeInterval(interval),
            endAt: endAt.addingTimeInterval(interval)
        )
    }

    /// Extend or shrink the slot's start time
    func withStart(_ newStart: Date) -> TimeSlot {
        TimeSlot(startAt: newStart, endAt: endAt)
    }

    /// Extend or shrink the slot's end time
    func withEnd(_ newEnd: Date) -> TimeSlot {
        TimeSlot(startAt: startAt, endAt: newEnd)
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

// MARK: - CustomStringConvertible

extension TimeSlot: CustomStringConvertible {
    var description: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startAt)) - \(formatter.string(from: endAt))"
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
