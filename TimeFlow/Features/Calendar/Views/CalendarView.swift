import SwiftUI
import SwiftData

/// Main calendar view with timeline grid and plan blocks
struct CalendarView: View {
    @Binding var selectedDate: Date
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @Environment(\.modelContext) private var modelContext

    @State private var displayMode: DisplayMode = .overlay
    @State private var isCreatingBlock = false
    @State private var editingBlock: PlanBlockModel?
    @State private var dragState: DragState = .idle

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

    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
    }

    var body: some View {
        HSplitView {
            // Main timeline
            VStack(spacing: 0) {
                // Toolbar
                calendarToolbar

                Divider()

                // Timeline grid
                ScrollView {
                    TimelineGridView(
                        date: selectedDate,
                        planBlocks: displayMode == .actualOnly ? [] : planBlocks,
                        actualBlocks: displayMode == .planOnly ? [] : actualBlocks,
                        displayMode: displayMode,
                        hourHeight: appEnvironment.userSettings.hourHeight,
                        onBlockTap: { block in
                            editingBlock = block
                        },
                        onEmptySlotTap: { slot in
                            createBlock(at: slot)
                        },
                        onBlockMove: { block, newSlot in
                            moveBlock(block, to: newSlot)
                        },
                        onBlockResize: { block, newSlot in
                            resizeBlock(block, to: newSlot)
                        }
                    )
                }
            }
            .frame(minWidth: 400)

            // Right sidebar - Tasks
            TaskSidebarView(selectedDate: $selectedDate)
                .frame(minWidth: 250, maxWidth: 350)
        }
        .sheet(item: $editingBlock) { block in
            PlanBlockEditorSheet(
                block: block,
                onSave: { try? updateBlock(block) },
                onDelete: { try? deleteBlock(block) }
            )
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
    }

    // MARK: - Toolbar

    private var calendarToolbar: some View {
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

            // Display mode picker
            Picker("Display", selection: $displayMode) {
                ForEach(DisplayMode.allCases, id: \.self) { mode in
                    Label(mode.title, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 250)

            Spacer()

            // Add block button
            Button(action: { isCreatingBlock = true }) {
                Label("New Block", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        .padding()
    }

    // MARK: - Actions

    private func navigateDay(_ days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func createBlock(at slot: TimeSlot) {
        // Quick create with default title
        do {
            _ = try appEnvironment.useCases.createPlanBlock.execute(
                date: selectedDate,
                startAt: slot.startAt,
                endAt: slot.endAt,
                title: "New Block"
            )
        } catch {
            print("Error creating block: \(error)")
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

    private func updateBlock(_ block: PlanBlockModel) throws {
        try appEnvironment.useCases.updatePlanBlock.execute(
            id: block.id,
            title: block.title,
            note: block.note,
            categoryId: block.categoryId,
            isFixed: block.isFixed
        )
        editingBlock = nil
    }

    private func deleteBlock(_ block: PlanBlockModel) throws {
        try appEnvironment.useCases.deletePlanBlock.execute(id: block.id)
        editingBlock = nil
    }

    private func moveBlock(_ block: PlanBlockModel, to newSlot: TimeSlot) {
        do {
            try appEnvironment.useCases.updatePlanBlock.move(
                id: block.id,
                to: newSlot.startAt,
                endAt: newSlot.endAt
            )
        } catch {
            print("Error moving block: \(error)")
        }
    }

    private func resizeBlock(_ block: PlanBlockModel, to newSlot: TimeSlot) {
        do {
            try appEnvironment.useCases.updatePlanBlock.resize(
                id: block.id,
                newStartAt: newSlot.startAt,
                newEndAt: newSlot.endAt
            )
        } catch {
            print("Error resizing block: \(error)")
        }
    }
}

// MARK: - Drag State

enum DragState {
    case idle
    case dragging(block: PlanBlockModel, offset: CGSize)
    case resizing(block: PlanBlockModel, edge: Edge)

    enum Edge {
        case top, bottom
    }
}

// MARK: - Preview

#Preview {
    CalendarView(selectedDate: .constant(Date()))
        .environmentObject(AppEnvironment())
}
