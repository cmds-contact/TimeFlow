import SwiftUI
import SwiftData

@main
struct TimeFlowApp: App {
    var body: some Scene {
        WindowGroup {
            WorkView()
        }
        .modelContainer(for: TimeBlock.self)
        .windowStyle(.automatic)
        .defaultSize(width: 800, height: 600)
    }
}
