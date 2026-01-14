import SwiftUI

/// Bar chart comparing planned vs actual time
struct PlanVsActualChart: View {
    let plannedMinutes: Int
    let actualMinutes: Int

    private var maxMinutes: Int {
        max(plannedMinutes, actualMinutes, 60)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Plan vs Actual")
                .font(.headline)

            // Chart
            VStack(spacing: 12) {
                // Planned bar
                chartBar(
                    label: "Planned",
                    minutes: plannedMinutes,
                    color: .blue
                )

                // Actual bar
                chartBar(
                    label: "Actual",
                    minutes: actualMinutes,
                    color: .green
                )
            }

            // Legend
            HStack(spacing: 20) {
                legendItem(color: .blue, label: "Planned")
                legendItem(color: .green, label: "Actual")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Chart Bar

    private func chartBar(label: String, minutes: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .leading)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.1))

                        // Bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color.gradient)
                            .frame(width: barWidth(for: minutes, in: geometry.size.width))
                    }
                }
                .frame(height: 24)

                Text(formatMinutes(minutes))
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(width: 60, alignment: .trailing)
            }
        }
    }

    // MARK: - Legend Item

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }

    // MARK: - Helpers

    private func barWidth(for minutes: Int, in totalWidth: CGFloat) -> CGFloat {
        guard maxMinutes > 0 else { return 0 }
        return totalWidth * CGFloat(minutes) / CGFloat(maxMinutes)
    }

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
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PlanVsActualChart(
            plannedMinutes: 300,
            actualMinutes: 270
        )

        PlanVsActualChart(
            plannedMinutes: 240,
            actualMinutes: 360
        )

        PlanVsActualChart(
            plannedMinutes: 0,
            actualMinutes: 120
        )
    }
    .padding()
    .frame(width: 500)
}
