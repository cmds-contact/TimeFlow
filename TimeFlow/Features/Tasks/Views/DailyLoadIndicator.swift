import SwiftUI

/// Visual indicator for daily task load
struct DailyLoadIndicator: View {
    let result: DailyLoadResult

    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: progressWidth(for: geometry.size.width))
                }
            }
            .frame(height: 8)

            // Labels
            HStack {
                // Status
                HStack(spacing: 4) {
                    Image(systemName: result.status.icon)
                        .foregroundStyle(statusColor)

                    Text(result.status.title)
                        .fontWeight(.medium)
                        .foregroundStyle(statusColor)
                }

                Spacer()

                // Time info
                Text("\(result.formattedEstimated) / \(result.formattedCapacity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("(\(Int(result.loadPercentage))%)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(statusColor)
            }

            // Remaining time
            if result.remainingMinutes > 0 {
                Text("\(result.formattedRemaining) remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if result.remainingMinutes < 0 {
                Text("\(TimeFormatter.shared.formatDuration(minutes: -result.remainingMinutes)) over capacity")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch result.status {
        case .ok:
            return .green
        case .warning:
            return .orange
        case .overload:
            return .red
        }
    }

    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        let percentage = min(result.loadPercentage / 100, 1.2) // Cap at 120% for display
        return totalWidth * CGFloat(percentage)
    }
}

// MARK: - Preview

#Preview("OK Status") {
    DailyLoadIndicator(result: DailyLoadResult(
        totalEstimatedMinutes: 240,
        capacityMinutes: 480,
        remainingMinutes: 240,
        completedMinutes: 0,
        loadPercentage: 50,
        status: .ok
    ))
    .padding()
    .frame(width: 300)
}

#Preview("Warning Status") {
    DailyLoadIndicator(result: DailyLoadResult(
        totalEstimatedMinutes: 420,
        capacityMinutes: 480,
        remainingMinutes: 60,
        completedMinutes: 0,
        loadPercentage: 87.5,
        status: .warning
    ))
    .padding()
    .frame(width: 300)
}

#Preview("Overload Status") {
    DailyLoadIndicator(result: DailyLoadResult(
        totalEstimatedMinutes: 600,
        capacityMinutes: 480,
        remainingMinutes: -120,
        completedMinutes: 0,
        loadPercentage: 125,
        status: .overload
    ))
    .padding()
    .frame(width: 300)
}
