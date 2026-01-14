import SwiftUI
import SwiftData

/// Main view with timeline and timer controls
struct WorkView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimeBlock.startAt) private var allBlocks: [TimeBlock]

    @State private var timer = StopwatchTimer()
    @State private var selectedDate = Date()
    @State private var selectedBlock: TimeBlock?
    @State private var editingBlock: TimeBlock?
    @State private var isNewBlock = false

    // Filter blocks for selected date
    private var todayBlocks: [TimeBlock] {
        allBlocks.filter { block in
            Calendar.current.isDate(block.startAt, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
            Divider()

            // Timeline
            TimelineView(
                blocks: todayBlocks,
                selectedDate: selectedDate,
                onBlockTap: { block in
                    editingBlock = block
                    isNewBlock = false
                },
                onEmptyTap: { slot in
                    createBlock(at: slot)
                }
            )
        }
        .sheet(item: $editingBlock) { block in
            BlockEditorSheet(
                block: block,
                isNew: isNewBlock,
                onDelete: {
                    modelContext.delete(block)
                }
            )
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 16) {
            // Date navigation
            dateNavigation

            Spacer()

            // Timer controls
            timerControls
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var dateNavigation: some View {
        HStack(spacing: 8) {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Button {
                selectedDate = Date()
            } label: {
                Text(formatDate(selectedDate))
                    .fontWeight(.medium)
            }
            .buttonStyle(.plain)

            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
        }
    }

    private var timerControls: some View {
        HStack(spacing: 12) {
            if timer.isIdle {
                // Start button
                Button {
                    timer.start()
                } label: {
                    Label("Start Timer", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            } else {
                // Timer display
                Text(timer.formattedTime)
                    .font(.system(.title2, design: .monospaced))
                    .foregroundStyle(timer.isRunning ? .primary : .secondary)

                // Pause/Resume
                Button {
                    if timer.isRunning {
                        timer.pause()
                    } else {
                        timer.resume()
                    }
                } label: {
                    Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.bordered)

                // Stop
                Button {
                    stopTimerAndCreateBlock()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }

    // MARK: - Actions

    private func createBlock(at slot: TimeSlot) {
        let block = TimeBlock(
            startAt: slot.startAt,
            endAt: slot.endAt,
            title: "",
            source: TimeBlock.sourceManual
        )
        modelContext.insert(block)
        editingBlock = block
        isNewBlock = true
    }

    private func stopTimerAndCreateBlock() {
        guard let slot = timer.stop() else { return }

        let block = TimeBlock(
            startAt: slot.startAt,
            endAt: slot.endAt,
            title: "",
            source: TimeBlock.sourceTimer
        )
        modelContext.insert(block)
        editingBlock = block
        isNewBlock = true
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Preview

#Preview {
    WorkView()
        .modelContainer(for: TimeBlock.self, inMemory: true)
        .frame(width: 800, height: 600)
}
