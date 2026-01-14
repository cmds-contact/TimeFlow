import SwiftUI

/// View for a single actual (recorded) block on the timeline
struct ActualBlockView: View {
    let block: ActualBlockModel
    let hourHeight: Double
    let baseDate: Date
    let isOverlay: Bool
    var isSelected: Bool = false

    @State private var isHovered = false

    private let timeCalculator = TimeCalculator()

    private var yPosition: CGFloat {
        timeCalculator.yPosition(for: block.startAt, hourHeight: hourHeight)
    }

    private var height: CGFloat {
        timeCalculator.height(for: block.timeSlot, hourHeight: hourHeight)
    }

    var body: some View {
        HStack(spacing: 4) {
            // Source indicator
            Image(systemName: block.source.icon)
                .font(.caption2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                // Title or default
                Text(block.title ?? "Recorded Time")
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                // Duration
                Text(TimeFormatter.shared.formatDuration(minutes: block.durationMinutes))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            // Link indicator
            if block.isLinked {
                Image(systemName: "link")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: max(24, height))
        .background(blockBackground)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(
                    isSelected ? Color.green : (isHovered ? Color.green : Color.green.opacity(0.5)),
                    lineWidth: isSelected ? 3 : 1
                )
        )
        .offset(x: isOverlay ? 70 : 58, y: yPosition)
        .padding(.trailing, isOverlay ? 20 : 8)
        .opacity(isOverlay ? 0.85 : 1)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    // MARK: - Background

    private var blockBackground: some View {
        Group {
            if isSelected {
                Color.green.opacity(0.35)
            } else {
                Color.green.opacity(isHovered ? 0.25 : 0.15)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let block = ActualBlockModel(
        startAt: Date().withTime(hour: 9, minute: 15),
        endAt: Date().withTime(hour: 10, minute: 0),
        title: "Coding session",
        source: .timer
    )

    return ZStack {
        Color.gray.opacity(0.1)

        ActualBlockView(
            block: block,
            hourHeight: 60,
            baseDate: Date(),
            isOverlay: true
        )
    }
    .frame(height: 400)
}
