import Foundation

/// Statistics for daily plan items
struct DailyPlanStats {
    /// Total estimated minutes for all items
    let totalMinutes: Int

    /// Estimated minutes for incomplete items
    let incompleteMinutes: Int

    /// Estimated minutes for completed items
    let completedMinutes: Int

    /// Available minutes in the day (from settings)
    let availableMinutes: Int

    /// Surplus (positive) or deficit (negative) minutes
    var surplusMinutes: Int {
        availableMinutes - totalMinutes
    }

    /// Total item count
    let totalCount: Int

    /// Completed item count
    let completedCount: Int

    /// Completion percentage (0-100)
    var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount) * 100
    }

    /// Formatted total time string
    var totalTimeString: String {
        formatMinutes(totalMinutes)
    }

    /// Formatted available time string
    var availableTimeString: String {
        formatMinutes(availableMinutes)
    }

    /// Formatted surplus time string with sign
    var surplusTimeString: String {
        let sign = surplusMinutes >= 0 ? "+" : ""
        return sign + formatMinutes(abs(surplusMinutes))
    }

    /// Is under capacity
    var isUnderCapacity: Bool {
        surplusMinutes >= 0
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(mins)m"
    }
}

/// Use case for calculating daily plan statistics
@MainActor
final class CalculateDailyPlanStatsUseCase {

    // MARK: - Dependencies

    private let repository: DailyPlanItemRepository
    private let settings: UserSettings

    // MARK: - Initialization

    init(repository: DailyPlanItemRepository, settings: UserSettings) {
        self.repository = repository
        self.settings = settings
    }

    // MARK: - Execute

    func execute(for date: Date) throws -> DailyPlanStats {
        let totalMinutes = try repository.totalEstimatedMinutes(for: date)
        let incompleteMinutes = try repository.incompleteEstimatedMinutes(for: date)
        let completedMinutes = try repository.completedEstimatedMinutes(for: date)
        let totalCount = try repository.itemCount(for: date)
        let completedCount = try repository.completedCount(for: date)

        // Calculate available minutes from user settings
        let startHour = settings.dayViewStartHour
        let endHour = settings.dayViewEndHour
        let availableMinutes = (endHour - startHour) * 60

        return DailyPlanStats(
            totalMinutes: totalMinutes,
            incompleteMinutes: incompleteMinutes,
            completedMinutes: completedMinutes,
            availableMinutes: availableMinutes,
            totalCount: totalCount,
            completedCount: completedCount
        )
    }
}
