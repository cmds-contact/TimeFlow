import SwiftUI
import SwiftData

@main
struct TimeFlowApp: App {
    @StateObject private var appEnvironment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appEnvironment)
                .modelContainer(appEnvironment.modelContainer)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1200, height: 800)
        .commands {
            TimeFlowCommands()
        }

        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(appEnvironment)
                .modelContainer(appEnvironment.modelContainer)
        }
        #endif
    }
}

// MARK: - App Commands
struct TimeFlowCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Plan Block") {
                NotificationCenter.default.post(name: .createNewPlanBlock, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command])

            Button("New Task") {
                NotificationCenter.default.post(name: .createNewTask, object: nil)
            }
            .keyboardShortcut("t", modifiers: [.command])

            Divider()

            Button("Start Focus") {
                NotificationCenter.default.post(name: .startFocus, object: nil)
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
        }

        CommandGroup(after: .toolbar) {
            Button("Today") {
                NotificationCenter.default.post(name: .navigateToToday, object: nil)
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])

            Divider()

            // DayFlow subpage shortcuts
            Button("Plan Page") {
                NotificationCenter.default.post(name: .dayFlowSwitchToPlan, object: nil)
            }
            .keyboardShortcut("1", modifiers: [.command])

            Button("Work Page") {
                NotificationCenter.default.post(name: .dayFlowSwitchToWork, object: nil)
            }
            .keyboardShortcut("2", modifiers: [.command])

            Button("Review Page") {
                NotificationCenter.default.post(name: .dayFlowSwitchToReview, object: nil)
            }
            .keyboardShortcut("3", modifiers: [.command])
        }

        // Edit menu - Delete selected block
        CommandGroup(after: .pasteboard) {
            Button("Delete Selected Block") {
                NotificationCenter.default.post(name: .deleteSelectedBlock, object: nil)
            }
            .keyboardShortcut(.delete, modifiers: [])
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let createNewPlanBlock = Notification.Name("createNewPlanBlock")
    static let createNewTask = Notification.Name("createNewTask")
    static let startFocus = Notification.Name("startFocus")
    static let navigateToToday = Notification.Name("navigateToToday")
    static let deleteSelectedBlock = Notification.Name("deleteSelectedBlock")
    // DayFlow subpage navigation
    static let dayFlowSwitchToPlan = Notification.Name("dayFlowSwitchToPlan")
    static let dayFlowSwitchToWork = Notification.Name("dayFlowSwitchToWork")
    static let dayFlowSwitchToReview = Notification.Name("dayFlowSwitchToReview")
}
