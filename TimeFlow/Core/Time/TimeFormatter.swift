import Foundation

/// Centralized time formatting utilities
struct TimeFormatter {

    // MARK: - Singleton

    static let shared = TimeFormatter()

    // MARK: - Formatters

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter
    }()

    private let hourMinuteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    // MARK: - Time Formatting

    /// Format time only (e.g., "9:30 AM")
    func formatTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// Format hour only (e.g., "9AM")
    func formatHour(_ date: Date) -> String {
        hourFormatter.string(from: date)
    }

    /// Format hour and minute (e.g., "9:30 AM")
    func formatHourMinute(_ date: Date) -> String {
        hourMinuteFormatter.string(from: date)
    }

    // MARK: - Date Formatting

    /// Format date only (e.g., "Jan 15, 2025")
    func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    /// Format date and time (e.g., "Jan 15, 2025 at 9:30 AM")
    func formatDateTime(_ date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    /// Format as ISO 8601
    func formatISO8601(_ date: Date) -> String {
        iso8601Formatter.string(from: date)
    }

    // MARK: - Duration Formatting

    /// Format duration in minutes to human-readable (e.g., "1h 30m")
    func formatDuration(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if remainingMinutes == 0 {
            return "\(hours)h"
        }

        return "\(hours)h \(remainingMinutes)m"
    }

    /// Format duration in minutes to full words (e.g., "1 hour 30 minutes")
    func formatDurationFull(minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        var parts: [String] = []

        if hours > 0 {
            parts.append(hours == 1 ? "1 hour" : "\(hours) hours")
        }

        if remainingMinutes > 0 {
            parts.append(remainingMinutes == 1 ? "1 minute" : "\(remainingMinutes) minutes")
        }

        if parts.isEmpty {
            return "0 minutes"
        }

        return parts.joined(separator: " ")
    }

    /// Format seconds to timer display (MM:SS or HH:MM:SS)
    func formatTimer(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }

        return String(format: "%02d:%02d", minutes, secs)
    }

    /// Format seconds to compact timer (e.g., "25:00" or "1:30:00")
    func formatTimerCompact(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }

        return String(format: "%d:%02d", minutes, secs)
    }

    // MARK: - Time Range Formatting

    /// Format a time range (e.g., "9:00 AM - 10:30 AM")
    func formatTimeRange(start: Date, end: Date) -> String {
        "\(formatTime(start)) - \(formatTime(end))"
    }

    /// Format a time slot
    func formatTimeSlot(_ slot: TimeSlot) -> String {
        formatTimeRange(start: slot.startAt, end: slot.endAt)
    }

    // MARK: - Relative Time

    /// Format relative time (e.g., "in 5 minutes", "2 hours ago")
    func formatRelative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Format relative time short (e.g., "5 min", "2 hr ago")
    func formatRelativeShort(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Parsing

    /// Parse time string (e.g., "9:30 AM") to Date on current day
    func parseTime(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        if let time = formatter.date(from: string) {
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())

            var combinedComponents = todayComponents
            combinedComponents.hour = timeComponents.hour
            combinedComponents.minute = timeComponents.minute

            return calendar.date(from: combinedComponents)
        }

        return nil
    }
}
