import Foundation
import Combine

/// Service for managing timers (manual tracking and Pomodoro)
@MainActor
final class TimerService: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var timerState: TimerState = .idle
    @Published private(set) var pomodoroState: PomodoroState = .idle
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var remainingSeconds: Int = 0

    // MARK: - Dependencies

    private let actualBlockRepository: ActualBlockRepository
    private let timeCalculator: TimeCalculator
    private let userDefaults: UserDefaults

    // MARK: - Timer Properties

    private var timer: Timer?
    private var timerStartDate: Date?
    private var timerEndDate: Date?
    private var linkedTaskId: UUID?
    private var linkedPlanBlockId: UUID?

    // Pomodoro specific
    private var pomodoroSessionId: UUID?
    private var focusDurationMinutes: Int = 25
    private var shortBreakMinutes: Int = 5
    private var longBreakMinutes: Int = 15
    private var cyclesBeforeLongBreak: Int = 4
    private var completedFocusSessions: [TimeSlot] = []

    // MARK: - Keys for UserDefaults

    private enum Keys {
        static let timerData = "TimeFlow.TimerData"
        static let pomodoroData = "TimeFlow.PomodoroData"
    }

    // MARK: - Initialization

    init(
        actualBlockRepository: ActualBlockRepository,
        timeCalculator: TimeCalculator,
        userDefaults: UserDefaults = .standard
    ) {
        self.actualBlockRepository = actualBlockRepository
        self.timeCalculator = timeCalculator
        self.userDefaults = userDefaults
    }

    // MARK: - Manual Timer (Stopwatch Mode)

    /// Start a manual tracking timer
    func startManualTimer(linkedTaskId: UUID? = nil, linkedPlanBlockId: UUID? = nil) {
        stopTimer()

        self.linkedTaskId = linkedTaskId
        self.linkedPlanBlockId = linkedPlanBlockId
        self.timerStartDate = Date()
        self.elapsedSeconds = 0
        self.timerState = .running(startedAt: Date())

        startTickTimer()
        persistTimerState()
    }

    /// Stop the manual timer and create an ActualBlock
    func stopManualTimer() async throws -> ActualBlockModel? {
        guard case .running(let startedAt) = timerState else { return nil }

        stopTimer()

        let endAt = Date()
        let block = try await actualBlockRepository.create(
            startAt: startedAt,
            endAt: endAt,
            title: nil,
            source: .timer,
            linkedPlanBlockId: linkedPlanBlockId
        )

        clearPersistedState()
        timerState = .idle
        elapsedSeconds = 0

        return block
    }

    /// Pause the current timer
    func pauseTimer() {
        guard case .running = timerState else { return }

        timer?.invalidate()
        timer = nil

        timerState = .paused(pausedAt: Date(), elapsedSeconds: elapsedSeconds)
        persistTimerState()
    }

    /// Resume a paused timer
    func resumeTimer() {
        guard case .paused(_, let elapsed) = timerState,
              let originalStart = timerStartDate else { return }

        // Adjust start time to account for pause duration
        let adjustedStart = Date().addingTimeInterval(-Double(elapsed))
        timerStartDate = adjustedStart
        timerState = .running(startedAt: adjustedStart)

        startTickTimer()
        persistTimerState()
    }

    // MARK: - Pomodoro Timer

    /// Start a new Pomodoro session
    func startPomodoro(
        focusMinutes: Int,
        shortBreakMinutes: Int,
        longBreakMinutes: Int,
        cycles: Int,
        linkedTaskId: UUID? = nil,
        linkedPlanBlockId: UUID? = nil
    ) {
        stopTimer()

        self.pomodoroSessionId = UUID()
        self.focusDurationMinutes = focusMinutes
        self.shortBreakMinutes = shortBreakMinutes
        self.longBreakMinutes = longBreakMinutes
        self.cyclesBeforeLongBreak = cycles
        self.linkedTaskId = linkedTaskId
        self.linkedPlanBlockId = linkedPlanBlockId
        self.completedFocusSessions = []

        startFocusPhase(cycle: 1, totalCycles: cycles)
    }

    private func startFocusPhase(cycle: Int, totalCycles: Int) {
        timerStartDate = Date()
        remainingSeconds = focusDurationMinutes * 60
        pomodoroState = .focusing(
            remainingSeconds: remainingSeconds,
            cycle: cycle,
            totalCycles: totalCycles
        )

        startCountdownTimer()
        persistPomodoroState()
    }

    private func startBreakPhase(cycle: Int, totalCycles: Int, isLongBreak: Bool) {
        timerStartDate = Date()
        let breakMinutes = isLongBreak ? longBreakMinutes : shortBreakMinutes
        remainingSeconds = breakMinutes * 60
        pomodoroState = .breaking(
            remainingSeconds: remainingSeconds,
            cycle: cycle,
            totalCycles: totalCycles,
            isLongBreak: isLongBreak
        )

        startCountdownTimer()
        persistPomodoroState()
    }

    /// Pause the Pomodoro timer
    func pausePomodoro() {
        guard pomodoroState.isActive,
              let phase = pomodoroState.currentPhase else { return }

        timer?.invalidate()
        timer = nil

        pomodoroState = .paused(
            previousPhase: phase,
            remainingSeconds: remainingSeconds,
            cycle: pomodoroState.currentCycle,
            totalCycles: pomodoroState.totalCycles
        )

        persistPomodoroState()
    }

    /// Resume a paused Pomodoro
    func resumePomodoro() {
        guard case .paused(let phase, let remaining, let cycle, let total) = pomodoroState else { return }

        remainingSeconds = remaining

        switch phase {
        case .focus:
            pomodoroState = .focusing(remainingSeconds: remaining, cycle: cycle, totalCycles: total)
        case .shortBreak:
            pomodoroState = .breaking(remainingSeconds: remaining, cycle: cycle, totalCycles: total, isLongBreak: false)
        case .longBreak:
            pomodoroState = .breaking(remainingSeconds: remaining, cycle: cycle, totalCycles: total, isLongBreak: true)
        }

        startCountdownTimer()
        persistPomodoroState()
    }

    /// Skip the current phase
    func skipPhase() {
        handlePhaseComplete()
    }

    /// Stop the Pomodoro session
    func stopPomodoro() async throws {
        stopTimer()

        // Create ActualBlocks for completed focus sessions
        for session in completedFocusSessions {
            _ = try await actualBlockRepository.create(
                startAt: session.startAt,
                endAt: session.endAt,
                title: "Focus Session",
                source: .pomodoro,
                linkedPlanBlockId: linkedPlanBlockId
            )
        }

        clearPomodoroState()
    }

    // MARK: - Timer Logic

    private func startTickTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func startCountdownTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.countdownTick()
            }
        }
    }

    private func tick() {
        guard case .running(let startedAt) = timerState else { return }
        elapsedSeconds = Int(Date().timeIntervalSince(startedAt))
    }

    private func countdownTick() {
        remainingSeconds -= 1

        if remainingSeconds <= 0 {
            handlePhaseComplete()
        } else {
            // Update state with new remaining time
            switch pomodoroState {
            case .focusing(_, let cycle, let total):
                pomodoroState = .focusing(remainingSeconds: remainingSeconds, cycle: cycle, totalCycles: total)
            case .breaking(_, let cycle, let total, let isLong):
                pomodoroState = .breaking(remainingSeconds: remainingSeconds, cycle: cycle, totalCycles: total, isLongBreak: isLong)
            default:
                break
            }
        }
    }

    private func handlePhaseComplete() {
        timer?.invalidate()
        timer = nil

        switch pomodoroState {
        case .focusing(_, let cycle, let total):
            // Record the completed focus session
            if let start = timerStartDate {
                completedFocusSessions.append(TimeSlot(startAt: start, endAt: Date()))
            }

            // Determine if this is a long break
            let isLongBreak = cycle % cyclesBeforeLongBreak == 0

            if cycle >= total {
                // All cycles complete
                let totalMinutes = completedFocusSessions.reduce(0) { $0 + $1.durationMinutes }
                pomodoroState = .completed(totalFocusMinutes: totalMinutes)
                clearPomodoroState()
            } else {
                // Start break
                startBreakPhase(cycle: cycle, totalCycles: total, isLongBreak: isLongBreak)
            }

        case .breaking(_, let cycle, let total, _):
            // Start next focus cycle
            startFocusPhase(cycle: cycle + 1, totalCycles: total)

        default:
            break
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Persistence

    private func persistTimerState() {
        guard case .running(let startedAt) = timerState else { return }

        let data = PersistedTimerData(
            type: .stopwatch,
            startedAt: startedAt,
            pausedAt: nil,
            elapsedSecondsWhenPaused: nil,
            totalDurationSeconds: nil,
            linkedTaskId: linkedTaskId,
            linkedPlanBlockId: linkedPlanBlockId
        )

        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: Keys.timerData)
        }
    }

    private func persistPomodoroState() {
        guard let phase = pomodoroState.currentPhase,
              let startDate = timerStartDate else { return }

        let durationSeconds: Int
        switch pomodoroState.currentPhase {
        case .focus:
            durationSeconds = focusDurationMinutes * 60
        case .shortBreak:
            durationSeconds = shortBreakMinutes * 60
        case .longBreak:
            durationSeconds = longBreakMinutes * 60
        case .none:
            return
        }

        let data = PersistedPomodoroData(
            sessionId: pomodoroSessionId ?? UUID(),
            phase: phase,
            currentCycle: pomodoroState.currentCycle,
            totalCycles: pomodoroState.totalCycles,
            focusDurationMinutes: focusDurationMinutes,
            shortBreakMinutes: shortBreakMinutes,
            longBreakMinutes: longBreakMinutes,
            phaseStartedAt: startDate,
            phaseDurationSeconds: durationSeconds,
            linkedTaskId: linkedTaskId,
            linkedPlanBlockId: linkedPlanBlockId
        )

        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: Keys.pomodoroData)
        }
    }

    private func clearPersistedState() {
        userDefaults.removeObject(forKey: Keys.timerData)
    }

    private func clearPomodoroState() {
        userDefaults.removeObject(forKey: Keys.pomodoroData)
        pomodoroSessionId = nil
        completedFocusSessions = []
        pomodoroState = .idle
        remainingSeconds = 0
    }

    // MARK: - Restoration

    /// Restore timer state from persistence (call on app launch)
    func restore() async {
        // Try to restore manual timer
        if let data = userDefaults.data(forKey: Keys.timerData),
           let timerData = try? JSONDecoder().decode(PersistedTimerData.self, from: data) {

            if timerData.type == .stopwatch {
                timerStartDate = timerData.startedAt
                linkedTaskId = timerData.linkedTaskId
                linkedPlanBlockId = timerData.linkedPlanBlockId
                elapsedSeconds = Int(Date().timeIntervalSince(timerData.startedAt))
                timerState = .running(startedAt: timerData.startedAt)
                startTickTimer()
                return
            }
        }

        // Try to restore Pomodoro
        if let data = userDefaults.data(forKey: Keys.pomodoroData),
           let pomodoroData = try? JSONDecoder().decode(PersistedPomodoroData.self, from: data) {

            pomodoroSessionId = pomodoroData.sessionId
            focusDurationMinutes = pomodoroData.focusDurationMinutes
            shortBreakMinutes = pomodoroData.shortBreakMinutes
            longBreakMinutes = pomodoroData.longBreakMinutes
            linkedTaskId = pomodoroData.linkedTaskId
            linkedPlanBlockId = pomodoroData.linkedPlanBlockId
            timerStartDate = pomodoroData.phaseStartedAt

            // Calculate remaining time
            let elapsed = Int(Date().timeIntervalSince(pomodoroData.phaseStartedAt))
            let remaining = pomodoroData.phaseDurationSeconds - elapsed

            if remaining > 0 {
                remainingSeconds = remaining

                switch pomodoroData.phase {
                case .focus:
                    pomodoroState = .focusing(
                        remainingSeconds: remaining,
                        cycle: pomodoroData.currentCycle,
                        totalCycles: pomodoroData.totalCycles
                    )
                case .shortBreak:
                    pomodoroState = .breaking(
                        remainingSeconds: remaining,
                        cycle: pomodoroData.currentCycle,
                        totalCycles: pomodoroData.totalCycles,
                        isLongBreak: false
                    )
                case .longBreak:
                    pomodoroState = .breaking(
                        remainingSeconds: remaining,
                        cycle: pomodoroData.currentCycle,
                        totalCycles: pomodoroData.totalCycles,
                        isLongBreak: true
                    )
                }

                startCountdownTimer()
            } else {
                // Phase expired while app was closed
                handlePhaseComplete()
            }
        }
    }
}
