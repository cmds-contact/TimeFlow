import SwiftUI
import SwiftData

/// Main Pomodoro focus view
struct FocusView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment

    @Query private var allTasks: [TaskItemModel]
    @Query(sort: \PomodoroSessionModel.startAt, order: .reverse)
    private var recentSessions: [PomodoroSessionModel]

    @State private var selectedTaskId: UUID?
    @State private var isSettingsOpen = false

    private var timerService: TimerService {
        appEnvironment.timerService
    }

    private var incompleteTasks: [TaskItemModel] {
        allTasks.filter { $0.status == .todo }
    }

    private var todaySessions: [PomodoroSessionModel] {
        let calendar = Calendar.current
        return recentSessions.filter { calendar.isDateInToday($0.startAt) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Main content
            HStack(spacing: 0) {
                // Timer section
                timerSection
                    .frame(maxWidth: .infinity)

                Divider()

                // Right sidebar
                rightSidebar
                    .frame(width: 300)
            }
        }
        .navigationTitle("Focus")
        .onReceive(NotificationCenter.default.publisher(for: .startFocus)) { _ in
            startSession()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Pomodoro Focus")
                .font(.headline)

            Spacer()

            // Today's stats
            HStack(spacing: 16) {
                Label(
                    "\(todaySessions.reduce(0) { $0 + $1.completedCycles }) cycles",
                    systemImage: "flame.fill"
                )
                .foregroundStyle(.orange)

                Label(
                    TimeFormatter.shared.formatDuration(
                        minutes: todaySessions.reduce(0) { $0 + $1.totalFocusMinutes }
                    ),
                    systemImage: "clock.fill"
                )
                .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            Button(action: { isSettingsOpen = true }) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
        }
        .padding()
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(spacing: 32) {
            Spacer()

            // Timer display
            PomodoroTimerView(
                state: timerService.pomodoroState,
                remainingSeconds: timerService.remainingSeconds
            )

            // Controls
            controlButtons

            // Task selection
            taskSelector

            Spacer()
        }
        .padding()
    }

    // MARK: - Control Buttons

    @ViewBuilder
    private var controlButtons: some View {
        switch timerService.pomodoroState {
        case .idle, .completed:
            Button(action: startSession) {
                Label("Start Focus", systemImage: "play.fill")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.space, modifiers: [])

        case .focusing, .breaking:
            HStack(spacing: 16) {
                Button(action: { timerService.pausePomodoro() }) {
                    Label("Pause", systemImage: "pause.fill")
                }
                .buttonStyle(.bordered)

                Button(action: { timerService.skipPhase() }) {
                    Label("Skip", systemImage: "forward.fill")
                }
                .buttonStyle(.bordered)

                Button(role: .destructive, action: stopSession) {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
            }

        case .paused:
            HStack(spacing: 16) {
                Button(action: { timerService.resumePomodoro() }) {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.space, modifiers: [])

                Button(role: .destructive, action: stopSession) {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Task Selector

    private var taskSelector: some View {
        VStack(spacing: 8) {
            Text("Working on:")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Task", selection: $selectedTaskId) {
                Text("No task selected").tag(nil as UUID?)

                ForEach(incompleteTasks) { task in
                    Text(task.title).tag(task.id as UUID?)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 300)
        }
    }

    // MARK: - Right Sidebar

    private var rightSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Session history
            Text("Today's Sessions")
                .font(.headline)
                .padding()

            Divider()

            if todaySessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("No sessions yet")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(todaySessions) { session in
                    SessionHistoryRow(session: session)
                }
                .listStyle(.plain)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Actions

    private func startSession() {
        do {
            _ = try appEnvironment.useCases.startPomodoro.execute(
                linkedTaskId: selectedTaskId,
                linkedPlanBlockId: nil
            )
        } catch {
            print("Error starting session: \(error)")
        }
    }

    private func stopSession() {
        Task {
            do {
                try await appEnvironment.useCases.stopPomodoro.execute()
            } catch {
                print("Error stopping session: \(error)")
            }
        }
    }
}

// MARK: - Session History Row

struct SessionHistoryRow: View {
    let session: PomodoroSessionModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startAt.timeString)
                    .font(.subheadline)

                Text("\(session.completedCycles)/\(session.targetCycles) cycles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if session.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if session.isInProgress {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    FocusView()
        .environmentObject(AppEnvironment())
}
