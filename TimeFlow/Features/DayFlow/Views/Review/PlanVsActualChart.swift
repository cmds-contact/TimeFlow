import SwiftUI

/// Bar chart comparing planned vs actual time
struct PlanVsActualChart: View {
    let plannedMinutes: Int
    let actualMinutes: Int

    private var maxMinutes: Int {
        max(plannedMinutes, actualMinutes, 60)
    }

    private var efficiencyScore: Int {
        guard plannedMinutes > 0 else { return actualMinutes > 0 ? 100 : 0 }
        let ratio = Double(actualMinutes) / Double(plannedMinutes)
        // Score is highest when ratio is close to 1.0
        // Penalty for both under and over
        if ratio >= 0.9 && ratio <= 1.1 {
            return 100
        } else if ratio < 0.9 {
            return max(0, Int(ratio * 100))
        } else {
            // Over-time penalty
            return max(0, 100 - Int((ratio - 1.0) * 50))
        }
    }

    private var varianceText: String {
        let diff = actualMinutes - plannedMinutes
        if diff == 0 {
            return "On track"
        } else if diff > 0 {
            return "+\(formatMinutes(diff)) over"
        } else {
            return "\(formatMinutes(-diff)) under"
        }
    }

    private var varianceColor: Color {
        let diff = actualMinutes - plannedMinutes
        if abs(diff) <= plannedMinutes / 10 { // within 10%
            return .green
        } else if diff < 0 {
            return .orange
        } else {
            return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with efficiency score
            HStack {
                Text("Plan vs Actual")
                    .font(.headline)

                Spacer()

                // Efficiency badge
                HStack(spacing: 4) {
                    Image(systemName: efficiencyIcon)
                        .font(.caption)
                    Text("\(efficiencyScore)%")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                }
                .foregroundColor(efficiencyColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(efficiencyColor.opacity(0.1))
                .cornerRadius(8)
            }

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

            // Variance indicator
            HStack {
                // Legend
                HStack(spacing: 20) {
                    legendItem(color: .blue, label: "Planned")
                    legendItem(color: .green, label: "Actual")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                Spacer()

                // Variance
                Text(varianceText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(varianceColor)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var efficiencyIcon: String {
        if efficiencyScore >= 90 { return "checkmark.seal.fill" }
        else if efficiencyScore >= 70 { return "checkmark.circle.fill" }
        else if efficiencyScore >= 50 { return "exclamationmark.circle.fill" }
        else { return "xmark.circle.fill" }
    }

    private var efficiencyColor: Color {
        if efficiencyScore >= 90 { return .green }
        else if efficiencyScore >= 70 { return .blue }
        else if efficiencyScore >= 50 { return .orange }
        else { return .red }
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
