import SwiftUI
import SwiftData

/// Sub-page enum for DayFlow navigation
enum DayFlowSubPage: String, CaseIterable {
    case plan = "Plan"
    case work = "Work"
    case review = "Review"

    var icon: String {
        switch self {
        case .plan: return "list.bullet.clipboard"
        case .work: return "play.circle"
        case .review: return "chart.bar"
        }
    }

    var koreanTitle: String {
        switch self {
        case .plan: return "계획"
        case .work: return "일과"
        case .review: return "리뷰"
        }
    }
}

/// Main DayFlow view container with sub-page navigation
struct DayFlowView: View {
    @Binding var selectedDate: Date
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @Environment(\.modelContext) private var modelContext

    @State private var subPage: DayFlowSubPage = .plan
    @State private var isCreatingBlock = false
    @State private var currentError: TimelineError?

    // Query plan blocks for selected date
    @Query private var allPlanBlocks: [PlanBlockModel]
    @Query private var allActualBlocks: [ActualBlockModel]

    private var planBlocks: [PlanBlockModel] {
        let calendar = Calendar.current
        return allPlanBlocks.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.startAt < $1.startAt }
    }

    private var actualBlocks: [ActualBlockModel] {
        let calendar = Calendar.current
        return allActualBlocks.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.startAt < $1.startAt }
    }

    var body: some View {
        ZStack(alignment: .top) {
            HSplitView {
                // Main content area
                VStack(spacing: 0) {
                    // Toolbar
                    dayFlowToolbar

                    Divider()

                    // Sub-page content
                    switch subPage {
                    case .plan:
                        PlanPageView(
                            selectedDate: selectedDate,
                            planBlocks: planBlocks,
                            onBlockTap: { block in
                                appEnvironment.selectionState.selectPlan(block)
                            },
                            onEmptySlotTap: { slot in
                                createPlanBlock(at: slot)
                            },
                            onBlockMove: { block, newSlot in
                                moveBlock(block, to: newSlot)
                            },
                            onBlockResize: { block, newSlot in
                                resizeBlock(block, to: newSlot)
                            }
                        )
                    case .work:
                        WorkPageView(
                            selectedDate: selectedDate,
                            planBlocks: planBlocks,
                            actualBlocks: actualBlocks,
                            onActualBlockTap: { block in
                                appEnvironment.selectionState.selectActual(block)
                            },
                            onCreateActualBlock: { slot in
                                createActualBlock(at: slot)
                            }
                        )
                    case .review:
                        ReviewPageView(
                            selectedDate: selectedDate,
                            planBlocks: planBlocks,
                            actualBlocks: actualBlocks
                        )
                    }
                }
                .frame(minWidth: 600)

                // Right sidebar - Block detail or Tasks
                RightSidebarView(selectedDate: $selectedDate)
                    .environmentObject(appEnvironment.selectionState)
                    .frame(minWidth: 250, maxWidth: 350)
            }

            // Error banner overlay
            if let error = currentError {
                TimelineErrorBanner(error: error) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        currentError = nil
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .zIndex(100)
            }
        }
        .sheet(isPresented: $isCreatingBlock) {
            PlanBlockEditorSheet(
                date: selectedDate,
                onSave: { title, startAt, endAt, note, categoryId in
                    try? createNewBlock(
                        title: title,
                        startAt: startAt,
                        endAt: endAt,
                        note: note,
                        categoryId: categoryId
                    )
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewPlanBlock)) { _ in
            isCreatingBlock = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .deleteSelectedBlock)) { _ in
            deleteSelectedBlock()
        }
    }

    // MARK: - Toolbar

    private var dayFlowToolbar: some View {
        HStack {
            // Date navigation
            HStack(spacing: 8) {
                Button(action: { navigateDay(-1) }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)

                Button(action: { selectedDate = Date() }) {
                    Text("Today")
                }
                .buttonStyle(.bordered)

                Button(action: { navigateDay(1) }) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)

                Text(selectedDate.fullDateString)
                    .font(.headline)
            }

            Spacer()

            // Sub-page picker
            Picker("Page", selection: $subPage) {
                ForEach(DayFlowSubPage.allCases, id: \.self) { page in
                    Label(page.rawValue, systemImage: page.icon)
                        .tag(page)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 250)

            Spacer()

            // Context-specific actions
            switch subPage {
            case .plan:
                Button(action: { isCreatingBlock = true }) {
                    Label("New Block", systemImage: "plus")
                }
            case .work:
                // Timer button will be added in WorkPageView
                EmptyView()
            case .review:
                EmptyView()
            }
        }
        .padding()
    }

    // MARK: - Actions

    private func navigateDay(_ days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func createPlanBlock(at slot: TimeSlot) {
        do {
            _ = try appEnvironment.useCases.createPlanBlock.execute(
                date: selectedDate,
                startAt: slot.startAt,
                endAt: slot.endAt,
                title: "New Block"
            )
        } catch {
            print("Error creating plan block: \(error)")
        }
    }

    private func createActualBlock(at slot: TimeSlot) {
        do {
            _ = try appEnvironment.useCases.createActualBlock.execute(
                startAt: slot.startAt,
                endAt: slot.endAt,
                title: "New Block"
            )
        } catch {
            print("Error creating actual block: \(error)")
        }
    }

    private func createNewBlock(
        title: String,
        startAt: Date,
        endAt: Date,
        note: String?,
        categoryId: UUID?
    ) throws {
        _ = try appEnvironment.useCases.createPlanBlock.execute(
            date: selectedDate,
            startAt: startAt,
            endAt: endAt,
            title: title,
            note: note,
            categoryId: categoryId
        )
        isCreatingBlock = false
    }

    private func moveBlock(_ block: PlanBlockModel, to newSlot: TimeSlot) {
        do {
            try appEnvironment.useCases.updatePlanBlock.move(
                id: block.id,
                to: newSlot.startAt,
                endAt: newSlot.endAt
            )
        } catch UpdatePlanBlockUseCase.Error.overlapsWithExisting {
            showError(.overlap, message: "Cannot move here - overlaps with another block")
        } catch UpdatePlanBlockUseCase.Error.invalidTimeSlot {
            showError(.invalidTime, message: "Invalid time range")
        } catch {
            showError(.invalidTime, message: error.localizedDescription)
        }
    }

    private func resizeBlock(_ block: PlanBlockModel, to newSlot: TimeSlot) {
        do {
            try appEnvironment.useCases.updatePlanBlock.resize(
                id: block.id,
                newStartAt: newSlot.startAt,
                newEndAt: newSlot.endAt
            )
        } catch UpdatePlanBlockUseCase.Error.overlapsWithExisting {
            showError(.overlap, message: "Cannot resize - would overlap with another block")
        } catch UpdatePlanBlockUseCase.Error.invalidTimeSlot {
            showError(.invalidTime, message: "Invalid time range")
        } catch {
            showError(.invalidTime, message: error.localizedDescription)
        }
    }

    private func deleteSelectedBlock() {
        if let block = appEnvironment.selectionState.selectedPlanBlock {
            do {
                try appEnvironment.useCases.deletePlanBlock.execute(id: block.id)
                appEnvironment.selectionState.clearSelection()
            } catch {
                print("Error deleting plan block: \(error)")
            }
        } else if let block = appEnvironment.selectionState.selectedActualBlock {
            do {
                try appEnvironment.useCases.deleteActualBlock.execute(id: block.id)
                appEnvironment.selectionState.clearSelection()
            } catch {
                print("Error deleting actual block: \(error)")
            }
        }
    }

    // MARK: - Error Handling

    private func showError(_ type: TimelineError.ErrorType, message: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentError = TimelineError(message: message, type: type)
        }

        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut(duration: 0.2)) {
                if currentError?.message == message {
                    currentError = nil
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DayFlowView(selectedDate: .constant(Date()))
        .environmentObject(AppEnvironment())
}
