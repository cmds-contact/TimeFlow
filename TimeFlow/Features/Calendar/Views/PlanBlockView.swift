import SwiftUI

/// View for a single plan block on the timeline
struct PlanBlockView: View {
    let block: PlanBlockModel
    let hourHeight: Double
    let baseDate: Date
    let isDragging: Bool
    var onResizeEnd: ((ResizeHandle.Edge, CGFloat) -> Void)?

    @State private var isHovered = false
    @State private var isResizing = false

    private let timeCalculator = TimeCalculator()

    private var yPosition: CGFloat {
        timeCalculator.yPosition(for: block.startAt, hourHeight: hourHeight)
    }

    private var height: CGFloat {
        timeCalculator.height(for: block.timeSlot, hourHeight: hourHeight)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: max(30, height))
        .background(blockBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(
                    isDragging ? Color.accentColor : Color.clear,
                    lineWidth: 2
                )
        )
        .shadow(color: isDragging ? .black.opacity(0.2) : .clear, radius: 4, y: 2)
        .offset(x: 58, y: yPosition)
        .padding(.trailing, 8)
        .onHover { hovering in
            isHovered = hovering
        }
        .overlay(resizeHandles)
    }

    // MARK: - Background

    private var blockBackground: some View {
        Group {
            if block.isFixed {
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
                    onDragChanged: { _ in isResizing = true },
                    onDragEnded: { offset in
                        isResizing = false
                        onResizeEnd?(.top, offset)
                    }
                )
                .offset(x: 58, y: yPosition)

                Spacer()

                // Bottom handle
                ResizeHandle(
                    edge: .bottom,
                    onDragChanged: { _ in isResizing = true },
                    onDragEnded: { offset in
                        isResizing = false
                        onResizeEnd?(.bottom, offset)
                    }
                )
                .offset(x: 58, y: yPosition + height - 6)
            }
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
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
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
