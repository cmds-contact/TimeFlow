import SwiftUI

/// Card showing daily statistics summary
struct DailyStatsCard: View {
    let plannedMinutes: Int
    let actualMinutes: Int
    let varianceMinutes: Int
    let planBlockCount: Int
    let actualBlockCount: Int

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Daily Summary")
                    .font(.headline)
                Spacer()
            }

            // Main stats
            HStack(spacing: 0) {
                // Planned
                statItem(
                    title: "Planned",
                    value: formatMinutes(plannedMinutes),
                    subtitle: "\(planBlockCount) blocks",
                    color: .blue
                )

                Divider()
                    .frame(height: 60)

                // Actual
                statItem(
                    title: "Actual",
                    value: formatMinutes(actualMinutes),
                    subtitle: "\(actualBlockCount) blocks",
                    color: .green
                )

                Divider()
                    .frame(height: 60)

                // Variance
                statItem(
                    title: "Variance",
                    value: formatVariance(varianceMinutes),
                    subtitle: varianceDescription,
                    color: varianceColor
                )
            }

            // Efficiency indicator
            if plannedMinutes > 0 {
                VStack(spacing: 4) {
                    HStack {
                        Text("Efficiency")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(efficiency * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(efficiencyColor)
                                .frame(width: geometry.size.width * min(efficiency, 1.0))
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Stat Item

    private func statItem(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties

    private var efficiency: Double {
        guard plannedMinutes > 0 else { return 0 }
        return Double(actualMinutes) / Double(plannedMinutes)
    }

    private var efficiencyColor: Color {
        if efficiency >= 0.9 {
            return .green
        } else if efficiency >= 0.7 {
            return .yellow
        } else {
            return .red
        }
    }

    private var varianceColor: Color {
        if varianceMinutes >= 0 {
            return .green
        } else {
            return .red
        }
    }

    private var varianceDescription: String {
        if varianceMinutes > 0 {
            return "over planned"
        } else if varianceMinutes < 0 {
            return "under planned"
        } else {
            return "on target"
        }
    }

    // MARK: - Formatters

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(mins)m"
    }

    private func formatVariance(_ minutes: Int) -> String {
        let sign = minutes >= 0 ? "+" : ""
        return sign + formatMinutes(abs(minutes))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        DailyStatsCard(
            plannedMinutes: 300,
            actualMinutes: 270,
            varianceMinutes: -30,
            planBlockCount: 5,
            actualBlockCount: 4
        )

        DailyStatsCard(
            plannedMinutes: 240,
            actualMinutes: 280,
            varianceMinutes: 40,
            planBlockCount: 4,
            actualBlockCount: 5
        )
    }
    .padding()
    .frame(width: 500)
}
