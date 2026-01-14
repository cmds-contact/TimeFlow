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

// MARK: - Preview

#Preview {
    ReviewPageView(
        selectedDate: Date(),
        planBlocks: [],
        actualBlocks: []
    )
    .environmentObject(AppEnvironment())
}
