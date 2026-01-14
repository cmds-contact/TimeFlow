import SwiftUI

/// Footer showing daily plan statistics
struct PlanStatsFooter: View {
    let stats: DailyPlanStats

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))

                    // Progress
                    let progress = min(CGFloat(stats.totalMinutes) / CGFloat(stats.availableMinutes), 1.0)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(stats.isUnderCapacity ? Color.green : Color.red)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)

            // Stats row
            HStack {
                // Total
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(stats.totalTimeString)
                        .font(.caption)
                        .fontWeight(.medium)
                }

                Spacer()

                // Available
                VStack(alignment: .center, spacing: 2) {
                    Text("Available")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(stats.availableTimeString)
                        .font(.caption)
                        .fontWeight(.medium)
                }

                Spacer()

                // Surplus/Deficit
                VStack(alignment: .trailing, spacing: 2) {
                    Text(stats.isUnderCapacity ? "Surplus" : "Deficit")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(stats.surplusTimeString)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(stats.isUnderCapacity ? .green : .red)
                }
            }

            // Completion status
            if stats.totalCount > 0 {
                HStack {
                    Text("\(stats.completedCount)/\(stats.totalCount) completed")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(Int(stats.completionPercentage))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
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
