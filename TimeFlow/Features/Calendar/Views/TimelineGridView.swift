import SwiftUI

/// 24-hour timeline grid view
struct TimelineGridView: View {
    let date: Date
    let planBlocks: [PlanBlockModel]
    let actualBlocks: [ActualBlockModel]
    let displayMode: DisplayMode
    let hourHeight: Double

    let onBlockTap: (PlanBlockModel) -> Void
    let onEmptySlotTap: (TimeSlot) -> Void
    let onBlockMove: (PlanBlockModel, TimeSlot) -> Void
    let onBlockResize: (PlanBlockModel, TimeSlot) -> Void

    @State private var hoveredHour: Int?
    @State private var draggedBlock: PlanBlockModel?
    @State private var dragOffset: CGSize = .zero

    private let hours = Array(0..<24)
    private let timeCalculator = TimeCalculator()

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Hour grid lines
                VStack(spacing: 0) {
                    ForEach(hours, id: \.self) { hour in
                        HourRowView(hour: hour, isHovered: hoveredHour == hour)
                            .frame(height: hourHeight)
                            .onHover { hovering in
                                hoveredHour = hovering ? hour : nil
                            }
                            .onTapGesture {
                                let startTime = date.withTime(hour: hour, minute: 0)
                                let endTime = date.withTime(hour: hour + 1, minute: 0)
                                onEmptySlotTap(TimeSlot(startAt: startTime, endAt: endTime))
                            }
                    }
                }

                // Current time indicator
                CurrentTimeIndicator(hourHeight: hourHeight)

                // Plan blocks layer
                if displayMode != .actualOnly {
                    ForEach(planBlocks) { block in
                        PlanBlockView(
                            block: block,
                            hourHeight: hourHeight,
                            baseDate: date,
                            isDragging: draggedBlock?.id == block.id
                        )
                        .offset(draggedBlock?.id == block.id ? dragOffset : .zero)
                        .onTapGesture {
                            onBlockTap(block)
                        }
                        .gesture(dragGesture(for: block))
                    }
                }

                // Actual blocks layer
                if displayMode != .planOnly {
                    ForEach(actualBlocks) { block in
                        ActualBlockView(
                            block: block,
                            hourHeight: hourHeight,
                            baseDate: date,
                            isOverlay: displayMode == .overlay
                        )
                    }
                }
            }
            .frame(width: geometry.size.width, height: CGFloat(hours.count) * hourHeight)
        }
        .frame(height: CGFloat(hours.count) * hourHeight)
    }

    // MARK: - Drag Gesture

    private func dragGesture(for block: PlanBlockModel) -> some Gesture {
        DragGesture()
            .onChanged { value in
                draggedBlock = block
                dragOffset = value.translation
            }
            .onEnded { value in
                // Calculate new time based on drag offset
                let minutesOffset = Int(value.translation.height / (hourHeight / 60))
                let newStartAt = block.startAt.adding(minutes: minutesOffset)
                let newEndAt = block.endAt.adding(minutes: minutesOffset)

                let newSlot = TimeSlot(startAt: newStartAt, endAt: newEndAt)
                    .rounded(toMinutes: 15) // Snap to 15-minute intervals

                onBlockMove(block, newSlot)

                draggedBlock = nil
                dragOffset = .zero
            }
    }
}

// MARK: - Hour Row View

struct HourRowView: View {
    let hour: Int
    let isHovered: Bool

    private var hourLabel: String {
        let date = Date().withTime(hour: hour, minute: 0)
        return TimeFormatter.shared.formatHour(date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Hour label
            Text(hourLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)
                .padding(.trailing, 8)

            // Grid line
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 1)
                Spacer()
            }
        }
        .background(isHovered ? Color.accentColor.opacity(0.05) : Color.clear)
    }
}

// MARK: - Current Time Indicator

struct CurrentTimeIndicator: View {
    let hourHeight: Double

    private var yPosition: CGFloat {
        let now = Date()
        let minutesFromMidnight = now.minutesFromMidnight
        return CGFloat(minutesFromMidnight) * (hourHeight / 60)
    }

    var body: some View {
        if Calendar.current.isDateInToday(Date()) {
            HStack(spacing: 0) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .offset(x: 46)

                Rectangle()
                    .fill(Color.red)
                    .frame(height: 2)
            }
            .offset(y: yPosition)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        TimelineGridView(
            date: Date(),
            planBlocks: [],
            actualBlocks: [],
            displayMode: .overlay,
            hourHeight: 60,
            onBlockTap: { _ in },
            onEmptySlotTap: { _ in },
            onBlockMove: { _, _ in },
            onBlockResize: { _, _ in }
        )
    }
}
