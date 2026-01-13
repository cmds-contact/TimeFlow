import Foundation

/// Central time calculation logic used across the app
final class TimeCalculator: Sendable {

    // MARK: - Properties

    private let calendar: Calendar

    // MARK: - Initialization

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    // MARK: - Validation

    /// Validate that a time slot is valid
    func isValidSlot(startAt: Date, endAt: Date) -> Bool {
        endAt > startAt
    }

    /// Validate that a time slot has minimum duration (in minutes)
    func hasMinimumDuration(slot: TimeSlot, minimumMinutes: Int) -> Bool {
        slot.durationMinutes >= minimumMinutes
    }

    // MARK: - Overlap Detection

    /// Check if a time slot overlaps with any existing slots
    func hasOverlap(slot: TimeSlot, with existingSlots: [TimeSlot], excludingId: UUID? = nil) -> Bool {
        existingSlots.contains { existing in
            slot.overlaps(with: existing)
        }
    }

    /// Find all overlapping slots
    func findOverlaps(slot: TimeSlot, in existingSlots: [TimeSlot]) -> [TimeSlot] {
        existingSlots.filter { slot.overlaps(with: $0) }
    }

    /// Calculate total overlap duration between a slot and existing slots
    func calculateOverlapDuration(slot: TimeSlot, with existingSlots: [TimeSlot]) -> TimeInterval {
        var totalOverlap: TimeInterval = 0

        for existing in existingSlots {
            if let intersection = slot.intersection(with: existing) {
                totalOverlap += intersection.duration
            }
        }

        return totalOverlap
    }

    // MARK: - Day Boundaries

    /// Get the start of day for a given date
    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Get the end of day for a given date (11:59:59 PM)
    func endOfDay(for date: Date) -> Date {
        let start = calendar.startOfDay(for: date)
        return calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? date
    }

    /// Check if two dates are on the same day
    func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }

    /// Check if a date is today
    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    // MARK: - Time Slot Generation

    /// Generate time slots for a day view (e.g., hourly slots)
    func generateDaySlots(for date: Date, intervalMinutes: Int = 60) -> [TimeSlot] {
        let start = startOfDay(for: date)
        let slotsPerDay = (24 * 60) / intervalMinutes
        var slots: [TimeSlot] = []

        for i in 0..<slotsPerDay {
            let slotStart = calendar.date(
                byAdding: .minute,
                value: i * intervalMinutes,
                to: start
            ) ?? start

            let slotEnd = calendar.date(
                byAdding: .minute,
                value: (i + 1) * intervalMinutes,
                to: start
            ) ?? start

            slots.append(TimeSlot(startAt: slotStart, endAt: slotEnd))
        }

        return slots
    }

    // MARK: - Position Calculations (for UI)

    /// Calculate Y position for a time on a timeline
    func yPosition(for date: Date, dayStartHour: Int = 0, hourHeight: CGFloat) -> CGFloat {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        let adjustedHour = hour - dayStartHour
        let totalMinutes = CGFloat(adjustedHour * 60 + minute)

        return totalMinutes * (hourHeight / 60)
    }

    /// Calculate time from Y position on a timeline
    func time(fromYPosition y: CGFloat, dayStartHour: Int = 0, hourHeight: CGFloat, baseDate: Date) -> Date {
        let totalMinutes = Int(y / (hourHeight / 60))
        let hours = totalMinutes / 60 + dayStartHour
        let minutes = totalMinutes % 60

        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = min(23, max(0, hours))
        components.minute = min(59, max(0, minutes))

        return calendar.date(from: components) ?? baseDate
    }

    /// Calculate height for a time slot on a timeline
    func height(for slot: TimeSlot, hourHeight: CGFloat) -> CGFloat {
        CGFloat(slot.durationMinutes) * (hourHeight / 60)
    }

    // MARK: - Time Rounding

    /// Round a date to the nearest interval (in minutes)
    func round(_ date: Date, toNearestMinutes interval: Int) -> Date {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = components.minute ?? 0
        let roundedMinute = (minute / interval) * interval

        var roundedComponents = components
        roundedComponents.minute = roundedMinute
        roundedComponents.second = 0

        return calendar.date(from: roundedComponents) ?? date
    }

    /// Snap a date to the next interval boundary
    func snapToNextInterval(_ date: Date, intervalMinutes: Int) -> Date {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = components.minute ?? 0
        let nextMinute = ((minute / intervalMinutes) + 1) * intervalMinutes

        var snappedComponents = components
        if nextMinute >= 60 {
            snappedComponents.hour = (components.hour ?? 0) + nextMinute / 60
            snappedComponents.minute = nextMinute % 60
        } else {
            snappedComponents.minute = nextMinute
        }
        snappedComponents.second = 0

        return calendar.date(from: snappedComponents) ?? date
    }

    // MARK: - Duration Formatting

    /// Format duration in minutes to human-readable string
    func formatDuration(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if remainingMinutes == 0 {
            return "\(hours)h"
        }

        return "\(hours)h \(remainingMinutes)m"
    }

    /// Format duration in seconds to timer display (MM:SS or HH:MM:SS)
    func formatTimer(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }

        return String(format: "%02d:%02d", minutes, secs)
    }

    // MARK: - Date Range

    /// Get dates for a range (for multi-day views)
    func dates(from startDate: Date, days: Int) -> [Date] {
        (0..<days).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startDate)
        }
    }

    /// Get the week containing a date
    func weekDates(containing date: Date) -> [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return [date]
        }

        return dates(from: weekInterval.start, days: 7)
    }
}

// MARK: - Block Layout Info

/// Layout information for a single block in an overlapping group
struct BlockLayoutInfo {
    let blockId: UUID
    let column: Int        // 0-indexed column position
    let totalColumns: Int  // Total columns in this overlap group
}

// MARK: - Overlap Layout Calculator

/// Calculates column layout for overlapping time blocks
/// Uses interval scheduling algorithm to assign blocks to columns
final class OverlapLayoutCalculator {

    /// Calculate layout for all blocks, returning column assignments
    /// - Parameter blocks: Array of plan blocks to layout
    /// - Returns: Dictionary mapping block IDs to their layout info
    func calculateLayout(for blocks: [PlanBlockModel]) -> [UUID: BlockLayoutInfo] {
        guard !blocks.isEmpty else { return [:] }

        // Sort blocks by start time
        let sortedBlocks = blocks.sorted { $0.startAt < $1.startAt }

        // Group overlapping blocks
        let groups = groupOverlappingBlocks(sortedBlocks)

        // Assign columns within each group
        var result: [UUID: BlockLayoutInfo] = [:]

        for group in groups {
            let columnAssignments = assignColumnsToGroup(group)
            let totalColumns = columnAssignments.values.max().map { $0 + 1 } ?? 1

            for block in group {
                let column = columnAssignments[block.id] ?? 0
                result[block.id] = BlockLayoutInfo(
                    blockId: block.id,
                    column: column,
                    totalColumns: totalColumns
                )
            }
        }

        return result
    }

    // MARK: - Private Methods

    /// Group blocks that overlap with each other
    private func groupOverlappingBlocks(_ sortedBlocks: [PlanBlockModel]) -> [[PlanBlockModel]] {
        var groups: [[PlanBlockModel]] = []
        var currentGroup: [PlanBlockModel] = []
        var groupEndTime: Date = .distantPast

        for block in sortedBlocks {
            if block.startAt < groupEndTime {
                // This block overlaps with the current group
                currentGroup.append(block)
                groupEndTime = max(groupEndTime, block.endAt)
            } else {
                // No overlap - start a new group
                if !currentGroup.isEmpty {
                    groups.append(currentGroup)
                }
                currentGroup = [block]
                groupEndTime = block.endAt
            }
        }

        // Don't forget the last group
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }

        return groups
    }

    /// Assign columns to blocks within a group using greedy scheduling
    private func assignColumnsToGroup(_ group: [PlanBlockModel]) -> [UUID: Int] {
        var columnAssignments: [UUID: Int] = [:]
        var columnEndTimes: [Date] = []

        // Process blocks in start time order
        let sorted = group.sorted { $0.startAt < $1.startAt }

        for block in sorted {
            var assignedColumn: Int? = nil

            // Find the first column where this block can fit
            for (columnIndex, endTime) in columnEndTimes.enumerated() {
                if block.startAt >= endTime {
                    // Block can fit in this column
                    assignedColumn = columnIndex
                    columnEndTimes[columnIndex] = block.endAt
                    break
                }
            }

            if assignedColumn == nil {
                // Need a new column
                assignedColumn = columnEndTimes.count
                columnEndTimes.append(block.endAt)
            }

            columnAssignments[block.id] = assignedColumn
        }

        return columnAssignments
    }
}
