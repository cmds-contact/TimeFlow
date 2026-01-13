import SwiftUI

/// User settings stored in UserDefaults via @AppStorage
@MainActor
final class UserSettings: ObservableObject {

    // MARK: - Pomodoro Settings

    /// Focus duration in minutes (default: 25)
    @AppStorage("focusDuration") var focusDuration: Int = 25

    /// Short break duration in minutes (default: 5)
    @AppStorage("shortBreakDuration") var shortBreakDuration: Int = 5

    /// Long break duration in minutes (default: 15)
    @AppStorage("longBreakDuration") var longBreakDuration: Int = 15

    /// Number of focus cycles before long break (default: 4)
    @AppStorage("cyclesBeforeLongBreak") var cyclesBeforeLongBreak: Int = 4

    /// Target number of pomodoro cycles per day (default: 8)
    @AppStorage("dailyPomodoroGoal") var dailyPomodoroGoal: Int = 8

    /// Auto-start break after focus ends
    @AppStorage("autoStartBreak") var autoStartBreak: Bool = true

    /// Auto-start focus after break ends
    @AppStorage("autoStartFocus") var autoStartFocus: Bool = false

    // MARK: - Available Time Settings

    /// Work day start time (minutes from midnight, default: 9:00 = 540)
    @AppStorage("availableTimeStart") var availableTimeStart: Int = 540

    /// Work day end time (minutes from midnight, default: 18:00 = 1080)
    @AppStorage("availableTimeEnd") var availableTimeEnd: Int = 1080

    /// Include weekends in available time
    @AppStorage("includeWeekends") var includeWeekends: Bool = false

    /// Computed available minutes per day
    var dailyAvailableMinutes: Int {
        availableTimeEnd - availableTimeStart
    }

    // MARK: - Calendar Settings

    /// Hour height in calendar view (default: 60 pixels)
    @AppStorage("hourHeight") var hourHeight: Double = 60

    /// Snap interval for block creation/resizing (minutes)
    @AppStorage("snapIntervalMinutes") var snapIntervalMinutes: Int = 15

    /// Default block duration when creating new blocks (minutes)
    @AppStorage("defaultBlockDuration") var defaultBlockDuration: Int = 60

    /// First hour to show in day view (24-hour format)
    @AppStorage("dayViewStartHour") var dayViewStartHour: Int = 6

    /// Last hour to show in day view (24-hour format)
    @AppStorage("dayViewEndHour") var dayViewEndHour: Int = 22

    // MARK: - Display Settings

    /// Default display mode
    @AppStorage("defaultDisplayMode") var defaultDisplayMode: String = "overlay"

    /// Show completed tasks
    @AppStorage("showCompletedTasks") var showCompletedTasks: Bool = true

    /// Theme preference (system, light, dark)
    @AppStorage("themePreference") var themePreference: String = "system"

    // MARK: - Notification Settings

    /// Enable timer end notifications
    @AppStorage("enableTimerNotifications") var enableTimerNotifications: Bool = true

    /// Enable daily summary notifications
    @AppStorage("enableDailySummary") var enableDailySummary: Bool = false

    /// Daily summary time (minutes from midnight)
    @AppStorage("dailySummaryTime") var dailySummaryTime: Int = 1200 // 8:00 PM

    // MARK: - Methods

    /// Get available time in minutes for a specific date
    func availableTime(for date: Date) -> Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        // Weekend check (1 = Sunday, 7 = Saturday)
        if !includeWeekends && (weekday == 1 || weekday == 7) {
            return 0
        }

        return dailyAvailableMinutes
    }

    /// Reset all settings to defaults
    func resetToDefaults() {
        focusDuration = 25
        shortBreakDuration = 5
        longBreakDuration = 15
        cyclesBeforeLongBreak = 4
        dailyPomodoroGoal = 8
        autoStartBreak = true
        autoStartFocus = false

        availableTimeStart = 540
        availableTimeEnd = 1080
        includeWeekends = false

        hourHeight = 60
        snapIntervalMinutes = 15
        defaultBlockDuration = 60
        dayViewStartHour = 6
        dayViewEndHour = 22

        defaultDisplayMode = "overlay"
        showCompletedTasks = true
        themePreference = "system"

        enableTimerNotifications = true
        enableDailySummary = false
        dailySummaryTime = 1200
    }
}

// MARK: - Display Mode Enum

enum DisplayMode: String, CaseIterable, Codable {
    case planOnly = "planOnly"
    case actualOnly = "actualOnly"
    case overlay = "overlay"

    var title: String {
        switch self {
        case .planOnly: return "Plan Only"
        case .actualOnly: return "Actual Only"
        case .overlay: return "Overlay"
        }
    }

    var icon: String {
        switch self {
        case .planOnly: return "calendar"
        case .actualOnly: return "clock"
        case .overlay: return "square.on.square"
        }
    }
}

// MARK: - Theme Enum

enum ThemePreference: String, CaseIterable {
    case system
    case light
    case dark

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
