import SwiftUI
import SwiftData

/// Work page with read-only plan timeline (left) and actual tracking timeline (right)
struct WorkPageView: View {
    let selectedDate: Date
    let planBlocks: [PlanBlockModel]
    let actualBlocks: [ActualBlockModel]
    let onActualBlockTap: (ActualBlockModel) -> Void
    let onCreateActualBlock: (TimeSlot) -> Void

    @EnvironmentObject private var appEnvironment: AppEnvironment
    @State private var showTimerSheet = false
    @State private var timerMode: TimerMode = .stopwatch

    enum TimerMode: String, CaseIterable {
        case stopwatch = "Stopwatch"
        case pomodoro = "Pomodoro"

        var icon: String {
            switch self {
            case .stopwatch: return "stopwatch"
            case .pomodoro: return "timer"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Timer toolbar
            timerToolbar

            Divider()

            // Dual timeline
            HSplitView {
                // Left - Plan blocks (read-only)
                VStack(spacing: 0) {
                    HStack {
                        Label("Today's Plan", systemImage: "list.bullet.clipboard")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    Divider()

                    ScrollView {
                        TimelineGridView(
                            date: selectedDate,
                            planBlocks: planBlocks,
                            actualBlocks: [],
                            displayMode: .planOnly,
                            hourHeight: appEnvironment.userSettings.hourHeight,
                            onBlockTap: { _ in },
                            onActualBlockTap: { _ in },
                            onEmptySlotTap: { _ in },
                            onBlockMove: { _, _ in },
                            onBlockResize: { _, _ in }
                        )
                        .environmentObject(appEnvironment.selectionState)
                    }
                    .allowsHitTesting(false)
                    .opacity(0.7)
                }
                .frame(minWidth: 300)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

                // Right - Actual blocks (editable)
                VStack(spacing: 0) {
                    HStack {
                        Label("Tracking", systemImage: "record.circle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()

                        // Quick timer status
                        if appEnvironment.timerService.timerState != .idle {
                            timerStatusBadge
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    Divider()

                    ScrollView {
                        TimelineGridView(
                            date: selectedDate,
                            planBlocks: [],
                            actualBlocks: actualBlocks,
                            displayMode: .actualOnly,
                            hourHeight: appEnvironment.userSettings.hourHeight,
                            onBlockTap: { _ in },
                            onActualBlockTap: onActualBlockTap,
                            onEmptySlotTap: onCreateActualBlock,
                            onBlockMove: { _, _ in },
                            onBlockResize: { _, _ in }
                        )
                        .environmentObject(appEnvironment.selectionState)
                    }
                }
                .frame(minWidth: 400)
            }
        }
        .sheet(isPresented: $showTimerSheet) {
            TimerModeSheet(
                mode: $timerMode,
                onStart: startTimer,
                onDismiss: { showTimerSheet = false }
            )
        }
    }

    // MARK: - Timer Toolbar

    private var timerToolbar: some View {
        HStack {
            // Timer mode selector
            Picker("Timer", selection: $timerMode) {
                ForEach(TimerMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            Spacer()

            // Timer controls
            if appEnvironment.timerService.timerState != .idle {
                // Active timer controls
                HStack(spacing: 12) {
                    // Elapsed time
                    Text(formatTime(appEnvironment.timerService.elapsedSeconds))
                        .font(.system(.title3, design: .monospaced))
                        .foregroundColor(.primary)

                    // Pause/Resume
                    Button(action: togglePause) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    }
                    .buttonStyle(.bordered)

                    // Stop
                    Button(action: stopTimer) {
                        Image(systemName: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            } else {
                // Start button
                Button(action: { showTimerSheet = true }) {
                    Label("Start Timer", systemImage: timerMode.icon)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    // MARK: - Timer Status Badge

    private var timerStatusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)

            Text(formatTime(appEnvironment.timerService.elapsedSeconds))
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Timer State

    private var isPaused: Bool {
        if case .paused = appEnvironment.timerService.timerState {
            return true
        }
        return false
    }

    // MARK: - Timer Actions

    private func startTimer() {
        showTimerSheet = false

        switch timerMode {
        case .stopwatch:
            appEnvironment.timerService.startManualTimer()
        case .pomodoro:
            do {
                _ = try appEnvironment.useCases.startPomodoro.execute(
                    linkedTaskId: nil,
                    linkedPlanBlockId: nil
                )
            } catch {
                print("Error starting pomodoro: \(error)")
            }
        }
    }

    private func togglePause() {
        switch appEnvironment.timerService.timerState {
        case .paused:
            appEnvironment.timerService.resumeTimer()
        case .running:
            appEnvironment.timerService.pauseTimer()
        default:
            break
        }
    }

    private func stopTimer() {
        Task {
            do {
                switch timerMode {
                case .stopwatch:
                    _ = try await appEnvironment.timerService.stopManualTimer()
                case .pomodoro:
                    try await appEnvironment.useCases.stopPomodoro.execute()
                }
            } catch {
                print("Error stopping timer: \(error)")
            }
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Timer Mode Sheet

struct TimerModeSheet: View {
    @Binding var mode: WorkPageView.TimerMode
    let onStart: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Start Timer")
                .font(.headline)

            Picker("Mode", selection: $mode) {
                ForEach(WorkPageView.TimerMode.allCases, id: \.self) { m in
                    Label(m.rawValue, systemImage: m.icon)
                        .tag(m)
                }
            }
            .pickerStyle(.segmented)

            Text(modeDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack {
                Button("Cancel", action: onDismiss)
                    .buttonStyle(.bordered)

                Button("Start", action: onStart)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 300)
    }

    private var modeDescription: String {
        switch mode {
        case .stopwatch:
            return "Track time freely. Press stop when finished to create an actual block."
        case .pomodoro:
            return "Focus in intervals with breaks. Actual blocks are created after each focus session."
        }
    }
}

// MARK: - Preview

#Preview {
    WorkPageView(
        selectedDate: Date(),
        planBlocks: [],
        actualBlocks: [],
        onActualBlockTap: { _ in },
        onCreateActualBlock: { _ in }
    )
    .environmentObject(AppEnvironment())
}
