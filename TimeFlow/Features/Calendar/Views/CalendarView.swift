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

    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
    }

    var body: some View {
        ZStack(alignment: .top) {
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
        // Quick create with default title based on display mode
        do {
            switch displayMode {
            case .actualOnly:
                _ = try appEnvironment.useCases.createActualBlock.execute(
                    startAt: slot.startAt,
                    endAt: slot.endAt,
                    title: "New Block"
                )
            case .planOnly, .overlay:
                _ = try appEnvironment.useCases.createPlanBlock.execute(
                    date: selectedDate,
                    startAt: slot.startAt,
                    endAt: slot.endAt,
                    title: "New Block"
                )
            }
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
            startAt: block.startAt,
            endAt: block.endAt,
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

// MARK: - Drag State

enum DragState {
    case idle
    case dragging(block: PlanBlockModel, offset: CGSize)
    case resizing(block: PlanBlockModel, edge: Edge)

    enum Edge {
        case top, bottom
    }
}

// MARK: - Timeline Error

struct TimelineError: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ErrorType

    enum ErrorType {
        case overlap
        case invalidTime
        case dayBoundary
    }
}

// MARK: - Timeline Error Banner

struct TimelineErrorBanner: View {
    let error: TimelineError
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Text(error.message)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.white)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
    }

    private var iconName: String {
        switch error.type {
        case .overlap:
            return "exclamationmark.triangle.fill"
        case .invalidTime:
            return "clock.badge.exclamationmark.fill"
        case .dayBoundary:
            return "calendar.badge.exclamationmark"
        }
    }

    private var backgroundColor: Color {
        switch error.type {
        case .overlap:
            return .orange
        case .invalidTime, .dayBoundary:
            return .red
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarView(selectedDate: .constant(Date()))
        .environmentObject(AppEnvironment())
}
