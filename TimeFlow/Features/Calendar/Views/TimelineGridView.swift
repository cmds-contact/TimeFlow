import SwiftUI

// MARK: - Drag State

enum TimelineDragState: Equatable {
    case idle
    case moving(blockId: UUID, offset: CGSize)
    case creating(startY: CGFloat, currentY: CGFloat)

    static func == (lhs: TimelineDragState, rhs: TimelineDragState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case let (.moving(id1, _), .moving(id2, _)):
            return id1 == id2
        case let (.creating(s1, c1), .creating(s2, c2)):
            return s1 == s2 && c1 == c2
        default:
            return false
        }
    }

    var isMoving: Bool {
        if case .moving = self { return true }
        return false
    }

    var isCreating: Bool {
        if case .creating = self { return true }
        return false
    }

    func movingBlockId() -> UUID? {
        if case let .moving(blockId, _) = self { return blockId }
        return nil
    }

    func movingOffset() -> CGSize {
        if case let .moving(_, offset) = self { return offset }
        return .zero
    }
}

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
    @State private var dragState: TimelineDragState = .idle

    private let hours = Array(0..<24)
    private let timeCalculator = TimeCalculator()
    private let layoutCalculator = OverlapLayoutCalculator()
    private let snapIntervalMinutes: Int = 5

    /// Computed layout info for overlapping blocks
    private var blockLayouts: [UUID: BlockLayoutInfo] {
        layoutCalculator.calculateLayout(for: planBlocks)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Hour grid lines with drag-to-create overlay
                VStack(spacing: 0) {
                    ForEach(hours, id: \.self) { hour in
                        HourRowView(hour: hour, isHovered: hoveredHour == hour)
                            .frame(height: hourHeight)
                            .onHover { hovering in
                                hoveredHour = hovering ? hour : nil
                            }
                    }
                }
                .contentShape(Rectangle())
                .highPriorityGesture(createBlockDragGesture)
                .onTapGesture {
                    // Handle tap only if not dragging
                    guard dragState == .idle else { return }
                    // Tap creates 1-hour block at the tapped hour
                    if let hour = hoveredHour {
                        let startTime = date.withTime(hour: hour, minute: 0)
                        let endHour = min(hour + 1, 23)
                        let endMinute = hour >= 23 ? 59 : 0
                        let endTime = date.withTime(hour: endHour, minute: endMinute)
                        onEmptySlotTap(TimeSlot(startAt: startTime, endAt: endTime))
                    }
                }

                // Creation preview overlay
                if case let .creating(startY, currentY) = dragState {
                    CreationPreviewView(
                        startY: startY,
                        currentY: currentY,
                        hourHeight: hourHeight,
                        snapIntervalMinutes: snapIntervalMinutes
                    )
                }

                // Current time indicator
                CurrentTimeIndicator(hourHeight: hourHeight)

                // Plan blocks layer
                if displayMode != .actualOnly {
                    ForEach(planBlocks) { block in
                        let isBeingDragged = dragState.movingBlockId() == block.id
                        let currentOffset = isBeingDragged ? dragState.movingOffset() : .zero
                        let layout = blockLayouts[block.id]

                        PlanBlockView(
                            block: block,
                            hourHeight: hourHeight,
                            baseDate: date,
                            isDragging: isBeingDragged,
                            columnIndex: layout?.column ?? 0,
                            totalColumns: layout?.totalColumns ?? 1,
                            availableWidth: geometry.size.width - 66, // 58 (label) + 8 (padding)
                            onResizeEnd: { edge, offset in
                                handleResize(block: block, edge: edge, offset: offset)
                            }
                        )
                        .offset(currentOffset)
                        .onTapGesture {
                            onBlockTap(block)
                        }
                        .gesture(dragGesture(for: block))
                    }

                    // Move preview overlay (snapped position)
                    if case let .moving(blockId, offset) = dragState,
                       let block = planBlocks.first(where: { $0.id == blockId }) {
                        MovePreviewView(
                            block: block,
                            offset: offset,
                            hourHeight: hourHeight,
                            snapIntervalMinutes: snapIntervalMinutes
                        )
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

    // MARK: - Create Block Drag Gesture

    private var createBlockDragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                // Only start creating if we're idle (not moving a block)
                if case .idle = dragState {
                    dragState = .creating(startY: value.startLocation.y, currentY: value.location.y)
                } else if case .creating(let startY, _) = dragState {
                    dragState = .creating(startY: startY, currentY: value.location.y)
                }
            }
            .onEnded { value in
                guard case let .creating(startY, currentY) = dragState else {
                    dragState = .idle
                    return
                }

                let minY = min(startY, currentY)
                let maxY = max(startY, currentY)

                let startTime = timeFromYPosition(minY)
                let endTime = timeFromYPosition(maxY)

                let slot = TimeSlot(startAt: startTime, endAt: endTime)
                    .rounded(toMinutes: snapIntervalMinutes)

                // Minimum duration check
                if slot.durationMinutes >= snapIntervalMinutes {
                    onEmptySlotTap(slot)
                }

                dragState = .idle
            }
    }

    /// Convert Y position to time on the given date
    private func timeFromYPosition(_ y: CGFloat) -> Date {
        let totalMinutes = Int(y / hourHeight * 60)
        let clampedMinutes = max(0, min(totalMinutes, 24 * 60 - 1))
        let hour = clampedMinutes / 60
        let minute = clampedMinutes % 60
        return date.withTime(hour: hour, minute: minute)
    }

    // MARK: - Block Move Drag Gesture

    private func dragGesture(for block: PlanBlockModel) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragState = .moving(blockId: block.id, offset: value.translation)
            }
            .onEnded { value in
                // Calculate new time based on drag offset
                let minutesOffset = Int(round(value.translation.height / (hourHeight / 60)))
                var newStartAt = block.startAt.adding(minutes: minutesOffset)
                var newEndAt = block.endAt.adding(minutes: minutesOffset)

                // Clamp to day boundaries
                let dayStart = date.startOfDay
                let dayEnd = date.endOfDay

                if newStartAt < dayStart {
                    let adjustment = dayStart.timeIntervalSince(newStartAt)
                    newStartAt = dayStart
                    newEndAt = newEndAt.addingTimeInterval(adjustment)
                }

                if newEndAt > dayEnd {
                    let adjustment = newEndAt.timeIntervalSince(dayEnd)
                    newEndAt = dayEnd
                    newStartAt = newStartAt.addingTimeInterval(-adjustment)
                    // Re-clamp start if it went negative
                    if newStartAt < dayStart {
                        newStartAt = dayStart
                    }
                }

                let newSlot = TimeSlot(startAt: newStartAt, endAt: newEndAt)
                    .rounded(toMinutes: snapIntervalMinutes)

                onBlockMove(block, newSlot)

                dragState = .idle
            }
    }

    // MARK: - Resize Handling

    private func handleResize(block: PlanBlockModel, edge: ResizeHandle.Edge, offset: CGFloat) {
        let minutesOffset = Int(round(offset / (hourHeight / 60)))
        var newStartAt = block.startAt
        var newEndAt = block.endAt

        switch edge {
        case .top:
            newStartAt = block.startAt.adding(minutes: minutesOffset)
        case .bottom:
            newEndAt = block.endAt.adding(minutes: minutesOffset)
        }

        // Clamp to day boundaries
        let dayStart = date.startOfDay
        let dayEnd = date.endOfDay
        newStartAt = max(dayStart, newStartAt)
        newEndAt = min(dayEnd, newEndAt)

        let newSlot = TimeSlot(startAt: newStartAt, endAt: newEndAt)
            .rounded(toMinutes: snapIntervalMinutes)

        // 최소 5분 유지
        guard newSlot.durationMinutes >= snapIntervalMinutes else { return }

        onBlockResize(block, newSlot)
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

// MARK: - Creation Preview View

struct CreationPreviewView: View {
    let startY: CGFloat
    let currentY: CGFloat
    let hourHeight: CGFloat
    let snapIntervalMinutes: Int

    /// Snapped start Y position
    private var snappedStartY: CGFloat {
        let pixelsPerInterval = hourHeight / 60 * CGFloat(snapIntervalMinutes)
        return (min(startY, currentY) / pixelsPerInterval).rounded() * pixelsPerInterval
    }

    /// Snapped end Y position
    private var snappedEndY: CGFloat {
        let pixelsPerInterval = hourHeight / 60 * CGFloat(snapIntervalMinutes)
        return (max(startY, currentY) / pixelsPerInterval).rounded() * pixelsPerInterval
    }

    /// Height of the preview
    private var previewHeight: CGFloat {
        let minHeight = hourHeight / 12 // Minimum 5-minute height
        return max(minHeight, snappedEndY - snappedStartY)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.green.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 2, dash: [6, 3]))
            )
            .frame(height: previewHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(x: 58, y: snappedStartY)
            .padding(.trailing, 8)
            .animation(.spring(response: 0.15, dampingFraction: 0.8), value: snappedStartY)
            .animation(.spring(response: 0.15, dampingFraction: 0.8), value: snappedEndY)
            .allowsHitTesting(false)
    }
}

// MARK: - Move Preview View

struct MovePreviewView: View {
    let block: PlanBlockModel
    let offset: CGSize
    let hourHeight: CGFloat
    let snapIntervalMinutes: Int

    private let timeCalculator = TimeCalculator()

    /// Calculate snapped Y offset (aligned to snap interval)
    private var snappedOffset: CGSize {
        let pixelsPerMinute = hourHeight / 60
        let pixelsPerInterval = pixelsPerMinute * CGFloat(snapIntervalMinutes)
        let snappedY = (offset.height / pixelsPerInterval).rounded() * pixelsPerInterval
        return CGSize(width: 0, height: snappedY)
    }

    private var yPosition: CGFloat {
        timeCalculator.yPosition(for: block.startAt, hourHeight: hourHeight)
    }

    private var height: CGFloat {
        timeCalculator.height(for: block.timeSlot, hourHeight: hourHeight)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.accentColor.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [6, 3]))
            )
            .frame(height: max(30, height))
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(x: 58, y: yPosition + snappedOffset.height)
            .padding(.trailing, 8)
            .animation(.spring(response: 0.15, dampingFraction: 0.8), value: snappedOffset)
            .allowsHitTesting(false)
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
