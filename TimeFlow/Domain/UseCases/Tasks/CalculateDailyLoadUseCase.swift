import Foundation

/// Load status for daily task capacity
enum LoadStatus: String, CaseIterable {
    case ok       // <= 80%
    case warning  // 80% - 100%
    case overload // > 100%

    var title: String {
        switch self {
        case .ok: return "OK"
        case .warning: return "Warning"
        case .overload: return "Overload"
        }
    }

    var icon: String {
        switch self {
        case .ok: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .overload: return "xmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .ok: return "#10B981"      // Green
        case .warning: return "#F59E0B" // Yellow
        case .overload: return "#EF4444" // Red
        }
    }
}

/// Result of daily load calculation
struct DailyLoadResult {
    let totalEstimatedMinutes: Int
    let capacityMinutes: Int
    let remainingMinutes: Int
    let completedMinutes: Int
    let loadPercentage: Double
    let status: LoadStatus

    var formattedEstimated: String {
        TimeFormatter.shared.formatDuration(minutes: totalEstimatedMinutes)
    }

    var formattedCapacity: String {
        TimeFormatter.shared.formatDuration(minutes: capacityMinutes)
    }

    var formattedRemaining: String {
        TimeFormatter.shared.formatDuration(minutes: max(0, remainingMinutes))
    }
}

/// Use case for calculating daily task load
@MainActor
final class CalculateDailyLoadUseCase {

    // MARK: - Dependencies

    private let repository: TaskRepository
    private let settings: UserSettings

    // MARK: - Initialization

    init(repository: TaskRepository, settings: UserSettings) {
        self.repository = repository
        self.settings = settings
    }

    // MARK: - Execute

    /// Calculate the daily load for a specific date
    func execute(for date: Date) throws -> DailyLoadResult {
        // Get capacity from settings
        let capacityMinutes = settings.availableTime(for: date)

        // Get tasks for the date
        let allTasks = try repository.fetchTasks(for: date)
        let incompleteTasks = allTasks.filter { $0.status == .todo }
        let completedTasks = allTasks.filter { $0.status == .done }

        // Calculate totals
        let totalEstimated = incompleteTasks.reduce(0) { $0 + $1.estimatedMinutes }
        let completedMinutes = completedTasks.reduce(0) { $0 + $1.estimatedMinutes }

        // Calculate percentage
        let percentage: Double
        if capacityMinutes > 0 {
            percentage = Double(totalEstimated) / Double(capacityMinutes) * 100
        } else {
            percentage = totalEstimated > 0 ? 100 : 0
        }

        // Determine status
        let status: LoadStatus
        switch percentage {
        case ..<80:
            status = .ok
        case 80..<100:
            status = .warning
        default:
            status = .overload
        }

        return DailyLoadResult(
            totalEstimatedMinutes: totalEstimated,
            capacityMinutes: capacityMinutes,
            remainingMinutes: capacityMinutes - totalEstimated,
            completedMinutes: completedMinutes,
            loadPercentage: percentage,
            status: status
        )
    }

    /// Quick check if a date is overloaded
    func isOverloaded(for date: Date) throws -> Bool {
        let result = try execute(for: date)
        return result.status == .overload
    }

    /// Get load status color for UI
    func loadColor(for date: Date) throws -> String {
        let result = try execute(for: date)
        return result.status.color
    }
}
