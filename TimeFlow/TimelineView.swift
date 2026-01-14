import SwiftUI

/// 24-hour timeline grid with time blocks
struct TimelineView: View {
    let blocks: [TimeBlock]
    let selectedDate: Date
    let onBlockTap: (TimeBlock) -> Void
    let onEmptyTap: (TimeSlot) -> Void

    private let hours = Array(0..<24)
    private let hourHeight: CGFloat = 60
    private let timeColumnWidth: CGFloat = 50

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    ZStack(alignment: .topLeading) {
                        // Hour grid
                        hourGrid

                        // Current time indicator
                        if Calendar.current.isDateInToday(selectedDate) {
                            CurrentTimeIndicator(hourHeight: hourHeight, timeColumnWidth: timeColumnWidth)
                        }

                        // Blocks
                        ForEach(blocks) { block in
                            BlockView(
                                block: block,
                                hourHeight: hourHeight,
                                timeColumnWidth: timeColumnWidth,
                                selectedDate: selectedDate
                            )
                            .onTapGesture {
                                onBlockTap(block)
                            }
                        }
                    }
                    .frame(height: CGFloat(hours.count) * hourHeight)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleEmptyTap(at: location)
                    }
                }
                .onAppear {
                    scrollToCurrentTime(proxy: proxy)
                }
            }
        }
    }

    // MARK: - Hour Grid

    private var hourGrid: some View {
        VStack(spacing: 0) {
            ForEach(hours, id: \.self) { hour in
                HourRow(hour: hour, timeColumnWidth: timeColumnWidth)
                    .frame(height: hourHeight)
                    .id(hour)
            }
        }
    }

    // MARK: - Actions

    private func handleEmptyTap(at location: CGPoint) {
        // Convert Y position to time
        let hour = Int(location.y / hourHeight)
        let minuteFraction = (location.y.truncatingRemainder(dividingBy: hourHeight)) / hourHeight
        let minute = Int(minuteFraction * 60)
        let roundedMinute = (minute / 15) * 15  // Round to 15min

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)

        guard let startAt = calendar.date(byAdding: .hour, value: hour, to: startOfDay),
              let startWithMinute = calendar.date(byAdding: .minute, value: roundedMinute, to: startAt),
              let endAt = calendar.date(byAdding: .minute, value: 30, to: startWithMinute) else {
            return
        }

        let slot = TimeSlot(startAt: startWithMinute, endAt: endAt)
        onEmptyTap(slot)
    }

    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        let hour = Calendar.current.component(.hour, from: Date())
        let targetHour = max(0, hour - 2)  // Show 2 hours before current
        proxy.scrollTo(targetHour, anchor: .top)
    }
}

// MARK: - Hour Row

private struct HourRow: View {
    let hour: Int
    let timeColumnWidth: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            // Time label
            Text(formatHour(hour))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: timeColumnWidth, alignment: .trailing)
                .padding(.trailing, 8)

            // Grid line
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Block View

private struct BlockView: View {
    let block: TimeBlock
    let hourHeight: CGFloat
    let timeColumnWidth: CGFloat
    let selectedDate: Date

    var body: some View {
        let position = calculatePosition()

        RoundedRectangle(cornerRadius: 6)
            .fill(blockColor)
            .overlay(
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: block.source == TimeBlock.sourceTimer ? "timer" : "pencil")
                            .font(.caption2)
                        Text(block.title.isEmpty ? "Untitled" : block.title)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    Text(formatDuration(block.durationMinutes))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            )
            .frame(width: position.width, height: position.height)
            .offset(x: position.x, y: position.y)
    }

    private var blockColor: Color {
        block.source == TimeBlock.sourceTimer
            ? Color.blue.opacity(0.3)
            : Color.green.opacity(0.3)
    }

    private func calculatePosition() -> (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)

        let startMinutes = calendar.dateComponents([.hour, .minute], from: startOfDay, to: block.startAt)
        let totalStartMinutes = (startMinutes.hour ?? 0) * 60 + (startMinutes.minute ?? 0)

        let y = CGFloat(totalStartMinutes) / 60.0 * hourHeight
        let height = CGFloat(block.durationMinutes) / 60.0 * hourHeight

        return (
            x: timeColumnWidth + 8,
            y: y,
            width: 200,
            height: max(height, 20)
        )
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - Current Time Indicator

private struct CurrentTimeIndicator: View {
    let hourHeight: CGFloat
    let timeColumnWidth: CGFloat

    var body: some View {
        let yPosition = calculateYPosition()

        HStack(spacing: 0) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .offset(x: timeColumnWidth - 4)

            Rectangle()
                .fill(Color.red)
                .frame(height: 1)
        }
        .offset(y: yPosition)
    }

    private func calculateYPosition() -> CGFloat {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        return (CGFloat(hour) + CGFloat(minute) / 60.0) * hourHeight
    }
}

// MARK: - Preview

#Preview {
    TimelineView(
        blocks: [],
        selectedDate: Date(),
        onBlockTap: { _ in },
        onEmptyTap: { _ in }
    )
    .frame(width: 400, height: 600)
}
