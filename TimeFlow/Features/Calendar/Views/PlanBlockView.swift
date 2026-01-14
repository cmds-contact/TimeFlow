import SwiftUI

/// View for a single plan block on the timeline
struct PlanBlockView: View {
    let block: PlanBlockModel
    let hourHeight: Double
    let baseDate: Date
    let isDragging: Bool
    var isSelected: Bool = false
    var columnIndex: Int = 0
    var totalColumns: Int = 1
    var availableWidth: CGFloat = 280
    var onResizeEnd: ((ResizeHandle.Edge, CGFloat) -> Void)?

    @State private var isHovered = false
    @State private var isResizing = false
    @State private var resizeOffset: CGFloat = 0
    @State private var resizingEdge: ResizeHandle.Edge?

    private let timeCalculator = TimeCalculator()
    private let snapIntervalMinutes: Int = 5
    private let columnGap: CGFloat = 2

    // MARK: - Column Layout

    /// Width of this block based on column layout
    private var blockWidth: CGFloat {
        let totalGaps = CGFloat(totalColumns - 1) * columnGap
        return (availableWidth - totalGaps) / CGFloat(totalColumns)
    }

    /// X offset based on column position
    private var xOffset: CGFloat {
        let baseOffset: CGFloat = 58 // Time label width + padding
        let columnWidth = blockWidth + columnGap
        return baseOffset + columnWidth * CGFloat(columnIndex)
    }

    // Base positions from actual block data
    private var baseYPosition: CGFloat {
        timeCalculator.yPosition(for: block.startAt, hourHeight: hourHeight)
    }

    private var baseHeight: CGFloat {
        timeCalculator.height(for: block.timeSlot, hourHeight: hourHeight)
    }

    // Snapped offset for preview (aligned to snap interval)
    private var snappedResizeOffset: CGFloat {
        let pixelsPerMinute = hourHeight / 60
        let pixelsPerInterval = pixelsPerMinute * CGFloat(snapIntervalMinutes)
        return (resizeOffset / pixelsPerInterval).rounded() * pixelsPerInterval
    }

    // Displayed position (adjusted during resize)
    private var yPosition: CGFloat {
        var position = baseYPosition
        if isResizing && resizingEdge == .top {
            position += resizeOffset  // 드래그 중 raw offset 사용
        }
        return position
    }

    // Displayed height (adjusted during resize)
    private var height: CGFloat {
        var h = baseHeight
        if isResizing {
            switch resizingEdge {
            case .top:
                h -= resizeOffset
            case .bottom:
                h += resizeOffset
            case .none:
                break
            }
        }
        // Minimum height for 5-minute block
        let minHeight = hourHeight / 12
        return max(minHeight, h)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Title
            Text(block.title)
                .font(.callout)
                .fontWeight(.medium)
                .lineLimit(1)

            // Time range
            Text(TimeFormatter.shared.formatTimeSlot(block.timeSlot))
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Note preview
            if let note = block.note, !note.isEmpty, height > 60 {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(width: blockWidth, alignment: .leading)
        .frame(height: max(30, height))
        .background(blockBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(
                    isSelected ? Color.accentColor : (isDragging ? Color.accentColor : Color.clear),
                    lineWidth: isSelected ? 3 : 2
                )
        )
        .shadow(color: isDragging ? .black.opacity(0.2) : .clear, radius: 4, y: 2)
        .offset(x: xOffset, y: yPosition)
        .onHover { hovering in
            isHovered = hovering
        }
        .overlay(resizeHandles)
    }

    // MARK: - Background

    private var blockBackground: some View {
        Group {
            if isSelected {
                Color.accentColor.opacity(0.35)
            } else if block.isFixed {
                Color.orange.opacity(0.3)
            } else {
                Color.accentColor.opacity(isHovered ? 0.25 : 0.15)
            }
        }
    }

    // MARK: - Resize Handles

    @ViewBuilder
    private var resizeHandles: some View {
        if isHovered || isResizing {
            VStack {
                // Top handle
                ResizeHandle(
                    edge: .top,
                    onDragChanged: { offset in
                        isResizing = true
                        resizingEdge = .top
                        resizeOffset = offset
                    },
                    onDragEnded: { offset in
                        isResizing = false
                        onResizeEnd?(.top, offset)
                        // Reset after callback
                        resizingEdge = nil
                        resizeOffset = 0
                    }
                )

                Spacer()

                // Bottom handle
                ResizeHandle(
                    edge: .bottom,
                    onDragChanged: { offset in
                        isResizing = true
                        resizingEdge = .bottom
                        resizeOffset = offset
                    },
                    onDragEnded: { offset in
                        isResizing = false
                        onResizeEnd?(.bottom, offset)
                        // Reset after callback
                        resizingEdge = nil
                        resizeOffset = 0
                    }
                )
            }
            .frame(width: blockWidth, height: height)
            .offset(x: xOffset, y: yPosition)
            .animation(.spring(response: 0.15, dampingFraction: 0.8), value: snappedResizeOffset)
        }
    }
}

// MARK: - Resize Handle

struct ResizeHandle: View {
    enum Edge { case top, bottom }

    let edge: Edge
    let onDragChanged: (CGFloat) -> Void
    let onDragEnded: (CGFloat) -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.accentColor)
            .frame(width: 40, height: 6)
            .opacity(0.6)
            .padding(.leading, 20)
            .contentShape(Rectangle().size(width: 60, height: 20)) // Larger hit area
            .highPriorityGesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        onDragChanged(value.translation.height)
                    }
                    .onEnded { value in
                        onDragEnded(value.translation.height)
                    }
            )
    }
}

// MARK: - Preview

#Preview {
    let block = PlanBlockModel(
        date: Date(),
        startAt: Date().withTime(hour: 9, minute: 0),
        endAt: Date().withTime(hour: 10, minute: 30),
        title: "Team Meeting",
        note: "Discuss Q1 goals and roadmap"
    )

    return ZStack {
        Color.gray.opacity(0.1)

        PlanBlockView(
            block: block,
            hourHeight: 60,
            baseDate: Date(),
            isDragging: false
        )
    }
    .frame(height: 400)
}
