import SwiftUI
import SwiftData

/// Plan page with daily plan table (left) and timeline (right)
struct PlanPageView: View {
    let selectedDate: Date
    let planBlocks: [PlanBlockModel]
    let onBlockTap: (PlanBlockModel) -> Void
    let onEmptySlotTap: (TimeSlot) -> Void
    let onBlockMove: (PlanBlockModel, TimeSlot) -> Void
    let onBlockResize: (PlanBlockModel, TimeSlot) -> Void

    @EnvironmentObject private var appEnvironment: AppEnvironment

    var body: some View {
        HSplitView {
            // Left section - Daily plan table
            DailyPlanTableView(selectedDate: selectedDate)
                .frame(minWidth: 300, idealWidth: 350)

            // Right section - Timeline
            ScrollView {
                TimelineGridView(
                    date: selectedDate,
                    planBlocks: planBlocks,
                    actualBlocks: [],
                    displayMode: .planOnly,
                    hourHeight: appEnvironment.userSettings.hourHeight,
                    onBlockTap: onBlockTap,
                    onActualBlockTap: { _ in },
                    onEmptySlotTap: onEmptySlotTap,
                    onBlockMove: onBlockMove,
                    onBlockResize: onBlockResize
                )
                .environmentObject(appEnvironment.selectionState)
            }
            .frame(minWidth: 400)
        }
    }
}

// MARK: - Preview

#Preview {
    PlanPageView(
        selectedDate: Date(),
        planBlocks: [],
        onBlockTap: { _ in },
        onEmptySlotTap: { _ in },
        onBlockMove: { _, _ in },
        onBlockResize: { _, _ in }
    )
    .environmentObject(AppEnvironment())
}
