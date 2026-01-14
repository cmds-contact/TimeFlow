import SwiftUI
import SwiftData

/// Review page showing daily statistics and Plan vs Actual comparison
struct ReviewPageView: View {
    let selectedDate: Date
    let planBlocks: [PlanBlockModel]
    let actualBlocks: [ActualBlockModel]

    @EnvironmentObject private var appEnvironment: AppEnvironment

    // Computed statistics
    private var plannedMinutes: Int {
        planBlocks.reduce(0) { $0 + $1.durationMinutes }
    }

    private var actualMinutes: Int {
        actualBlocks.reduce(0) { $0 + $1.durationMinutes }
    }

    private var varianceMinutes: Int {
        actualMinutes - plannedMinutes
    }

    // Hourly breakdown
    private var hourlyData: [HourlyComparisonData] {
        var data: [HourlyComparisonData] = []
        for hour in 6..<24 { // 6 AM to 11 PM
            let planMins = minutesInHour(hour, blocks: planBlocks.map { ($0.startAt, $0.endAt) })
            let actualMins = minutesInHour(hour, blocks: actualBlocks.map { ($0.startAt, $0.endAt) })
            if planMins > 0 || actualMins > 0 {
                data.append(HourlyComparisonData(hour: hour, plannedMinutes: planMins, actualMinutes: actualMins))
            }
        }
        return data
    }

    private func minutesInHour(_ hour: Int, blocks: [(Date, Date)]) -> Int {
        let calendar = Calendar.current
        var total = 0

        for (start, end) in blocks {
            let startHour = calendar.component(.hour, from: start)
            let endHour = calendar.component(.hour, from: end)

            if hour >= startHour && hour <= endHour {
                let hourStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: start)!
                let hourEnd = calendar.date(bySettingHour: hour, minute: 59, second: 59, of: start)!

                let effectiveStart = max(start, hourStart)
                let effectiveEnd = min(end, hourEnd)

                if effectiveEnd > effectiveStart {
                    total += Int(effectiveEnd.timeIntervalSince(effectiveStart) / 60)
                }
            }
        }
        return min(total, 60)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Daily stats card
                DailyStatsCard(
                    plannedMinutes: plannedMinutes,
                    actualMinutes: actualMinutes,
                    varianceMinutes: varianceMinutes,
                    planBlockCount: planBlocks.count,
                    actualBlockCount: actualBlocks.count
                )

                // Plan vs Actual chart
                PlanVsActualChart(
                    plannedMinutes: plannedMinutes,
                    actualMinutes: actualMinutes
                )

                // Hourly breakdown chart
                if !hourlyData.isEmpty {
                    HourlyComparisonChart(data: hourlyData)
                }

                // Session history
                SessionHistoryList(
                    planBlocks: planBlocks,
                    actualBlocks: actualBlocks
                )
            }
            .padding()
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Hourly Comparison Data

struct HourlyComparisonData: Identifiable {
    let id = UUID()
    let hour: Int
    let plannedMinutes: Int
    let actualMinutes: Int

    var hourLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date).lowercased()
    }
}

// MARK: - Hourly Comparison Chart

struct HourlyComparisonChart: View {
    let data: [HourlyComparisonData]

    private var maxMinutes: Int {
        max(data.map { max($0.plannedMinutes, $0.actualMinutes) }.max() ?? 60, 30)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hourly Breakdown")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(data) { item in
                        VStack(spacing: 4) {
                            // Bars
                            HStack(alignment: .bottom, spacing: 2) {
                                // Planned bar
                                VStack {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.blue.opacity(0.7))
                                        .frame(width: 12, height: barHeight(item.plannedMinutes))
                                }

                                // Actual bar
                                VStack {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.green.opacity(0.7))
                                        .frame(width: 12, height: barHeight(item.actualMinutes))
                                }
                            }
                            .frame(height: 80)

                            // Hour label
                            Text(item.hourLabel)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 16) {
                legendItem(color: .blue.opacity(0.7), label: "Planned")
                legendItem(color: .green.opacity(0.7), label: "Actual")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func barHeight(_ minutes: Int) -> CGFloat {
        guard maxMinutes > 0 else { return 0 }
        return max(4, CGFloat(minutes) / CGFloat(maxMinutes) * 80)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 8)
            Text(label)
        }
    }
}

// MARK: - Preview

#Preview {
    ReviewPageView(
        selectedDate: Date(),
        planBlocks: [],
        actualBlocks: []
    )
    .environmentObject(AppEnvironment())
}
