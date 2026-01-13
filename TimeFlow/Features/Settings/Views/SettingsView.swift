import SwiftUI

/// App settings view
struct SettingsView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment

    private var settings: UserSettings {
        appEnvironment.userSettings
    }

    var body: some View {
        TabView {
            // General settings
            generalSettings
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            // Pomodoro settings
            pomodoroSettings
                .tabItem {
                    Label("Pomodoro", systemImage: "timer")
                }

            // Calendar settings
            calendarSettings
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
        }
        .frame(width: 500, height: 400)
    }

    // MARK: - General Settings

    private var generalSettings: some View {
        Form {
            Section("Available Time") {
                HStack {
                    Text("Work day starts at")
                    Spacer()
                    TimePicker(minutesFromMidnight: Binding(
                        get: { settings.availableTimeStart },
                        set: { settings.availableTimeStart = $0 }
                    ))
                }

                HStack {
                    Text("Work day ends at")
                    Spacer()
                    TimePicker(minutesFromMidnight: Binding(
                        get: { settings.availableTimeEnd },
                        set: { settings.availableTimeEnd = $0 }
                    ))
                }

                Toggle("Include weekends", isOn: Binding(
                    get: { settings.includeWeekends },
                    set: { settings.includeWeekends = $0 }
                ))

                Text("Daily capacity: \(TimeFormatter.shared.formatDuration(minutes: settings.dailyAvailableMinutes))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Appearance") {
                Picker("Theme", selection: Binding(
                    get: { settings.themePreference },
                    set: { settings.themePreference = $0 }
                )) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }

                Toggle("Show completed tasks", isOn: Binding(
                    get: { settings.showCompletedTasks },
                    set: { settings.showCompletedTasks = $0 }
                ))
            }

            Section {
                Button("Reset to Defaults") {
                    settings.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Pomodoro Settings

    private var pomodoroSettings: some View {
        Form {
            Section("Durations") {
                Stepper(
                    "Focus: \(settings.focusDuration) minutes",
                    value: Binding(
                        get: { settings.focusDuration },
                        set: { settings.focusDuration = $0 }
                    ),
                    in: 5...60,
                    step: 5
                )

                Stepper(
                    "Short break: \(settings.shortBreakDuration) minutes",
                    value: Binding(
                        get: { settings.shortBreakDuration },
                        set: { settings.shortBreakDuration = $0 }
                    ),
                    in: 1...30,
                    step: 1
                )

                Stepper(
                    "Long break: \(settings.longBreakDuration) minutes",
                    value: Binding(
                        get: { settings.longBreakDuration },
                        set: { settings.longBreakDuration = $0 }
                    ),
                    in: 5...60,
                    step: 5
                )
            }

            Section("Cycles") {
                Stepper(
                    "Cycles before long break: \(settings.cyclesBeforeLongBreak)",
                    value: Binding(
                        get: { settings.cyclesBeforeLongBreak },
                        set: { settings.cyclesBeforeLongBreak = $0 }
                    ),
                    in: 2...8
                )

                Stepper(
                    "Daily goal: \(settings.dailyPomodoroGoal) cycles",
                    value: Binding(
                        get: { settings.dailyPomodoroGoal },
                        set: { settings.dailyPomodoroGoal = $0 }
                    ),
                    in: 1...20
                )
            }

            Section("Behavior") {
                Toggle("Auto-start break after focus", isOn: Binding(
                    get: { settings.autoStartBreak },
                    set: { settings.autoStartBreak = $0 }
                ))

                Toggle("Auto-start focus after break", isOn: Binding(
                    get: { settings.autoStartFocus },
                    set: { settings.autoStartFocus = $0 }
                ))
            }

            Section("Notifications") {
                Toggle("Timer notifications", isOn: Binding(
                    get: { settings.enableTimerNotifications },
                    set: { settings.enableTimerNotifications = $0 }
                ))
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Calendar Settings

    private var calendarSettings: some View {
        Form {
            Section("Display") {
                Slider(
                    value: Binding(
                        get: { settings.hourHeight },
                        set: { settings.hourHeight = $0 }
                    ),
                    in: 40...120,
                    step: 10
                ) {
                    Text("Hour height: \(Int(settings.hourHeight))px")
                }

                Stepper(
                    "Start hour: \(settings.dayViewStartHour):00",
                    value: Binding(
                        get: { settings.dayViewStartHour },
                        set: { settings.dayViewStartHour = $0 }
                    ),
                    in: 0...12
                )

                Stepper(
                    "End hour: \(settings.dayViewEndHour):00",
                    value: Binding(
                        get: { settings.dayViewEndHour },
                        set: { settings.dayViewEndHour = $0 }
                    ),
                    in: 18...24
                )
            }

            Section("Block Creation") {
                Picker("Snap interval", selection: Binding(
                    get: { settings.snapIntervalMinutes },
                    set: { settings.snapIntervalMinutes = $0 }
                )) {
                    Text("5 minutes").tag(5)
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                }

                Stepper(
                    "Default duration: \(settings.defaultBlockDuration) min",
                    value: Binding(
                        get: { settings.defaultBlockDuration },
                        set: { settings.defaultBlockDuration = $0 }
                    ),
                    in: 15...120,
                    step: 15
                )
            }

            Section("Default View") {
                Picker("Display mode", selection: Binding(
                    get: { settings.defaultDisplayMode },
                    set: { settings.defaultDisplayMode = $0 }
                )) {
                    Text("Plan Only").tag("planOnly")
                    Text("Actual Only").tag("actualOnly")
                    Text("Overlay").tag("overlay")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Time Picker

struct TimePicker: View {
    @Binding var minutesFromMidnight: Int

    private var hours: Int {
        minutesFromMidnight / 60
    }

    private var minutes: Int {
        minutesFromMidnight % 60
    }

    var body: some View {
        HStack {
            Picker("Hour", selection: Binding(
                get: { hours },
                set: { minutesFromMidnight = $0 * 60 + minutes }
            )) {
                ForEach(0..<24, id: \.self) { hour in
                    Text("\(hour)").tag(hour)
                }
            }
            .labelsHidden()
            .frame(width: 60)

            Text(":")

            Picker("Minute", selection: Binding(
                get: { minutes },
                set: { minutesFromMidnight = hours * 60 + $0 }
            )) {
                ForEach([0, 15, 30, 45], id: \.self) { min in
                    Text(String(format: "%02d", min)).tag(min)
                }
            }
            .labelsHidden()
            .frame(width: 60)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AppEnvironment())
}
