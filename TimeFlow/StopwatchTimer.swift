import Foundation
import Combine

/// Simple stopwatch timer (memory only, no persistence)
@MainActor
@Observable
final class StopwatchTimer {

    // MARK: - State

    enum State: Equatable {
        case idle
        case running(startedAt: Date)
        case paused(elapsed: TimeInterval)
    }

    // MARK: - Properties

    private(set) var state: State = .idle
    private(set) var elapsedSeconds: Int = 0
    private var timer: Timer?
    private var startedAt: Date?

    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    var isPaused: Bool {
        if case .paused = state { return true }
        return false
    }

    var isIdle: Bool {
        state == .idle
    }

    // MARK: - Actions

    func start() {
        guard isIdle else { return }
        let now = Date()
        startedAt = now
        state = .running(startedAt: now)
        elapsedSeconds = 0
        startTimer()
    }

    func pause() {
        guard case .running = state else { return }
        stopTimer()
        let elapsed = TimeInterval(elapsedSeconds)
        state = .paused(elapsed: elapsed)
    }

    func resume() {
        guard case .paused(let elapsed) = state else { return }
        let now = Date()
        startedAt = now.addingTimeInterval(-elapsed)
        state = .running(startedAt: startedAt!)
        startTimer()
    }

    /// Stop and return the time slot for block creation
    func stop() -> TimeSlot? {
        guard let start = startedAt else {
            reset()
            return nil
        }

        let end = Date()
        reset()

        let slot = TimeSlot(startAt: start, endAt: end)
        return slot.isValid ? slot : nil
    }

    func reset() {
        stopTimer()
        state = .idle
        elapsedSeconds = 0
        startedAt = nil
    }

    // MARK: - Private

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard case .running(let start) = state else { return }
        elapsedSeconds = Int(Date().timeIntervalSince(start))
    }
}

// MARK: - Formatting

extension StopwatchTimer {
    var formattedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
