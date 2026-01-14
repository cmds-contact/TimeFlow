import SwiftUI
import SwiftData

/// Main content view with tab-based navigation
struct ContentView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @State private var selectedTab: Tab = .dayflow
    @State private var selectedDate: Date = Date()

    enum Tab: String, CaseIterable {
        case dayflow = "DayFlow"
        case tasks = "Tasks"
        case focus = "Focus"

        var icon: String {
            switch self {
            case .dayflow: return "clock.arrow.2.circlepath"
            case .tasks: return "checklist"
            case .focus: return "timer"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .environment(\.useCases, appEnvironment.useCases)
        .environment(\.timeCalculator, appEnvironment.timeCalculator)
        .environment(\.userSettings, appEnvironment.userSettings)
        .task {
            await appEnvironment.restoreState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToToday)) { _ in
            selectedDate = Date()
            selectedTab = .dayflow
        }
    }

    // MARK: - Sidebar

    private var sidebarContent: some View {
        List(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("TimeFlow")
        .frame(minWidth: 180)
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case .dayflow:
            DayFlowView(selectedDate: $selectedDate)
        case .tasks:
            TaskListView(selectedDate: $selectedDate)
        case .focus:
            FocusView()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppEnvironment())
}
