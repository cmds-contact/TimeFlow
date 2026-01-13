import SwiftUI

/// Large circular Pomodoro timer display
struct PomodoroTimerView: View {
    let state: PomodoroState
    let remainingSeconds: Int

    @State private var animateRing = false

    private var progress: Double {
        // This would need the total seconds for accurate progress
        // For now, showing remaining time
        1.0
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                .frame(width: 280, height: 280)

            // Progress ring
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: remainingSeconds)

            // Center content
            VStack(spacing: 12) {
                // State label
                if let phase = state.currentPhase {
                    HStack(spacing: 6) {
                        Image(systemName: phase.icon)
                        Text(phase.title)
                    }
                    .font(.headline)
                    .foregroundStyle(ringColor)
                }

                // Time display
                Text(timeString)
                    .font(.system(size: 64, weight: .light, design: .monospaced))

                // Cycle progress
                if state.totalCycles > 0 {
                    HStack(spacing: 4) {
                        ForEach(0..<state.totalCycles, id: \.self) { index in
                            Circle()
                                .fill(index < state.currentCycle ? ringColor : Color.secondary.opacity(0.3))
                                .frame(width: 10, height: 10)
                        }
                    }
                }

                // Status message
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
    }

    // MARK: - Computed Properties

    private var timeString: String {
        TimeFormatter.shared.formatTimer(seconds: remainingSeconds)
    }

    private var ringColor: Color {
        switch state.currentPhase {
        case .focus:
            return .red
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        case .none:
            return .secondary
        }
    }

    private var ringProgress: Double {
        guard state.isActive || state.isPaused else { return 0 }

        // Calculate progress based on phase duration
        let totalSeconds: Int
        switch state.currentPhase {
        case .focus:
            totalSeconds = 25 * 60 // Default, should come from settings
        case .shortBreak:
            totalSeconds = 5 * 60
        case .longBreak:
            totalSeconds = 15 * 60
        case .none:
            return 0
        }

        return Double(remainingSeconds) / Double(totalSeconds)
    }

    private var statusMessage: String {
        switch state {
        case .idle:
            return "Ready to start"
        case .focusing:
            return "Stay focused!"
        case .breaking(_, _, _, let isLong):
            return isLong ? "Take a longer break" : "Take a short break"
        case .paused:
            return "Paused"
        case .completed(let minutes):
            return "Completed! \(TimeFormatter.shared.formatDuration(minutes: minutes)) focused"
        }
    }
}

// MARK: - Preview

#Preview("Idle") {
    PomodoroTimerView(
        state: .idle,
        remainingSeconds: 0
    )
}

#Preview("Focusing") {
    PomodoroTimerView(
        state: .focusing(remainingSeconds: 1500, cycle: 2, totalCycles: 4),
        remainingSeconds: 1500
    )
}

#Preview("Break") {
    PomodoroTimerView(
        state: .breaking(remainingSeconds: 300, cycle: 2, totalCycles: 4, isLongBreak: false),
        remainingSeconds: 300
    )
}

#Preview("Paused") {
    PomodoroTimerView(
        state: .paused(previousPhase: .focus, remainingSeconds: 800, cycle: 1, totalCycles: 4),
        remainingSeconds: 800
    )
}

#Preview("Completed") {
    PomodoroTimerView(
        state: .completed(totalFocusMinutes: 100),
        remainingSeconds: 0
    )
}
