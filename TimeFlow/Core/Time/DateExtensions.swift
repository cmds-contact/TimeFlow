import Foundation

extension Date {

    // MARK: - Day Boundaries

    /// Start of the day (midnight)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of the day (23:59:59)
    var endOfDay: Date {
        Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) ?? self
    }

    // MARK: - Adding Time

    /// Add minutes to date
    func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    /// Add hours to date
    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    /// Add days to date
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    // MARK: - Components

    /// Hour component (0-23)
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }

    /// Minute component (0-59)
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }

    /// Total minutes from midnight
    var minutesFromMidnight: Int {
        hour * 60 + minute
    }

    /// Weekday component (1 = Sunday, 7 = Saturday)
    var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }

    /// Check if weekend
    var isWeekend: Bool {
        weekday == 1 || weekday == 7
    }

    // MARK: - Comparisons

    /// Check if same day as another date
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// Check if today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Check if yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    // MARK: - Creating Dates

    /// Create a date with specific time on the same day
    func withTime(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components) ?? self
    }

    /// Create a date for today with specific time
    static func today(at hour: Int, minute: Int = 0) -> Date {
        Date().withTime(hour: hour, minute: minute)
    }

    // MARK: - Formatting

    /// Short date string (e.g., "Jan 15")
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    /// Time string (e.g., "9:30 AM")
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Full date string (e.g., "January 15, 2025")
    var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: self)
    }

    /// Relative date string (e.g., "Today", "Yesterday", "Jan 15")
    var relativeDateString: String {
        if isToday {
            return "Today"
        } else if isTomorrow {
            return "Tomorrow"
        } else if isYesterday {
            return "Yesterday"
        }
        return shortDateString
    }

    /// Day of week name (e.g., "Monday")
    var dayOfWeekName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    /// Short day of week name (e.g., "Mon")
    var shortDayOfWeekName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }
}

// MARK: - Date Interval Helpers

extension DateInterval {
    /// Duration in minutes
    var durationMinutes: Int {
        Int(duration / 60)
    }

    /// Check if interval contains a date
    func contains(date: Date) -> Bool {
        date >= start && date <= end
    }
}
