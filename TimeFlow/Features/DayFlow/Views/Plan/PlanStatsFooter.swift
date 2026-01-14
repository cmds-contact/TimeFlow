import SwiftUI

/// Footer showing daily plan statistics
struct PlanStatsFooter: View {
    let stats: DailyPlanStats

    private var loadPercentage: Double {
        guard stats.availableMinutes > 0 else { return 0 }
        return Double(stats.totalMinutes) / Double(stats.availableMinutes) * 100
    }

    private var loadColor: Color {
        if loadPercentage <= 80 {
            return .green
        } else if loadPercentage <= 100 {
            return .orange
        } else {
            return .red
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Circular progress + stats
            HStack(spacing: 16) {
                // Circular load indicator
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: min(CGFloat(loadPercentage) / 100, 1.0))
                        .stroke(loadColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(Int(min(loadPercentage, 999)))%")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(loadColor)
                        Text("load")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 56, height: 56)

                // Stats columns
                VStack(alignment: .leading, spacing: 8) {
                    // Time stats
                    HStack(spacing: 16) {
                        StatItem(title: "Planned", value: stats.totalTimeString, color: .primary)
                        StatItem(title: "Available", value: stats.availableTimeString, color: .secondary)
                        StatItem(
                            title: stats.isUnderCapacity ? "Buffer" : "Over",
                            value: stats.surplusTimeString,
                            color: stats.isUnderCapacity ? .green : .red
                        )
                    }

                    // Completion progress
                    if stats.totalCount > 0 {
                        HStack(spacing: 8) {
                            // Mini completion bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.secondary.opacity(0.2))

                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.blue)
                                        .frame(width: geometry.size.width * CGFloat(stats.completionPercentage) / 100)
                                }
                            }
                            .frame(width: 60, height: 4)

                            Text("\(stats.completedCount)/\(stats.totalCount) done")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        PlanStatsFooter(stats: DailyPlanStats(
            totalMinutes: 240,
            incompleteMinutes: 180,
            completedMinutes: 60,
            availableMinutes: 480,
            totalCount: 5,
            completedCount: 2
        ))

        PlanStatsFooter(stats: DailyPlanStats(
            totalMinutes: 600,
            incompleteMinutes: 500,
            completedMinutes: 100,
            availableMinutes: 480,
            totalCount: 8,
            completedCount: 2
        ))
    }
    .frame(width: 350)
}
