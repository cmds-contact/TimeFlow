import Foundation
import SwiftData

/// Repository for PomodoroSession CRUD operations
@MainActor
final class PomodoroRepository {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    /// Create a new Pomodoro session
    func create(
        focusMinutes: Int = 25,
        breakMinutes: Int = 5,
        longBreakMinutes: Int = 15,
        targetCycles: Int = 4,
        linkedTaskId: UUID? = nil,
        linkedPlanBlockId: UUID? = nil
    ) throws -> PomodoroSessionModel {
        let session = PomodoroSessionModel(
            focusMinutes: focusMinutes,
            breakMinutes: breakMinutes,
            longBreakMinutes: longBreakMinutes,
            targetCycles: targetCycles,
            linkedTaskId: linkedTaskId,
            linkedPlanBlockId: linkedPlanBlockId
        )

        modelContext.insert(session)
        try modelContext.save()

        return session
    }

    // MARK: - Read

    /// Fetch all sessions for a specific date
    func fetchSessions(for date: Date) throws -> [PomodoroSessionModel] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        let predicate = #Predicate<PomodoroSessionModel> { session in
            session.startAt >= startOfDay && session.startAt < endOfDay
        }

        let descriptor = FetchDescriptor<PomodoroSessionModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startAt)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Fetch completed sessions for a date
    func fetchCompletedSessions(for date: Date) throws -> [PomodoroSessionModel] {
        let sessions = try fetchSessions(for: date)
        return sessions.filter { $0.isCompleted }
    }

    /// Fetch the active (in-progress) session if any
    func fetchActiveSession() throws -> PomodoroSessionModel? {
        let predicate = #Predicate<PomodoroSessionModel> { session in
            session.endAt == nil
        }

        let descriptor = FetchDescriptor<PomodoroSessionModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startAt, order: .reverse)]
        )

        return try modelContext.fetch(descriptor).first
    }

    /// Fetch a specific session by ID
    func fetch(id: UUID) throws -> PomodoroSessionModel? {
        let predicate = #Predicate<PomodoroSessionModel> { session in
            session.id == id
        }

        let descriptor = FetchDescriptor<PomodoroSessionModel>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    /// Fetch sessions linked to a specific task
    func fetchSessions(linkedToTaskId taskId: UUID) throws -> [PomodoroSessionModel] {
        let predicate = #Predicate<PomodoroSessionModel> { session in
            session.linkedTaskId == taskId
        }

        let descriptor = FetchDescriptor<PomodoroSessionModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startAt)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Fetch all sessions
    func fetchAll() throws -> [PomodoroSessionModel] {
        let descriptor = FetchDescriptor<PomodoroSessionModel>(
            sortBy: [SortDescriptor(\.startAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Update

    /// Update an existing session
    func update(_ session: PomodoroSessionModel) throws {
        try modelContext.save()
    }

    /// Increment completed cycles for a session
    func incrementCycle(id: UUID) throws {
        guard let session = try fetch(id: id) else { return }
        session.incrementCycle()
        try modelContext.save()
    }

    /// Complete a session
    func complete(id: UUID) throws {
        guard let session = try fetch(id: id) else { return }
        session.complete()
        try modelContext.save()
    }

    // MARK: - Delete

    /// Delete a session
    func delete(_ session: PomodoroSessionModel) throws {
        modelContext.delete(session)
        try modelContext.save()
    }

    /// Delete a session by ID
    func delete(id: UUID) throws {
        guard let session = try fetch(id: id) else { return }
        modelContext.delete(session)
        try modelContext.save()
    }

    /// Delete incomplete sessions (cleanup)
    func deleteIncompleteSessions() throws {
        let predicate = #Predicate<PomodoroSessionModel> { session in
            session.endAt == nil
        }

        let descriptor = FetchDescriptor<PomodoroSessionModel>(predicate: predicate)
        let incompleteSessions = try modelContext.fetch(descriptor)

        for session in incompleteSessions {
            modelContext.delete(session)
        }

        try modelContext.save()
    }

    // MARK: - Statistics

    /// Get total focus minutes for a date
    func totalFocusMinutes(for date: Date) throws -> Int {
        let sessions = try fetchCompletedSessions(for: date)
        return sessions.reduce(0) { $0 + $1.totalFocusMinutes }
    }

    /// Get total completed cycles for a date
    func totalCompletedCycles(for date: Date) throws -> Int {
        let sessions = try fetchSessions(for: date)
        return sessions.reduce(0) { $0 + $1.completedCycles }
    }

    /// Get average cycles per session for a date range
    func averageCyclesPerSession(from startDate: Date, to endDate: Date) throws -> Double {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) ?? endDate

        let predicate = #Predicate<PomodoroSessionModel> { session in
            session.startAt >= start &&
            session.startAt < end &&
            session.endAt != nil
        }

        let descriptor = FetchDescriptor<PomodoroSessionModel>(predicate: predicate)
        let sessions = try modelContext.fetch(descriptor)

        guard !sessions.isEmpty else { return 0 }

        let totalCycles = sessions.reduce(0) { $0 + $1.completedCycles }
        return Double(totalCycles) / Double(sessions.count)
    }
}
