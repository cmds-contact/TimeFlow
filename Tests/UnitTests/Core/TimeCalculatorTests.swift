import XCTest
@testable import TimeFlow

final class TimeCalculatorTests: XCTestCase {
    var calculator: TimeCalculator!

    override func setUp() {
        super.setUp()
        calculator = TimeCalculator()
    }

    override func tearDown() {
        calculator = nil
        super.tearDown()
    }

    // MARK: - Validation Tests

    func testIsValidSlot_validSlot_returnsTrue() {
        let start = Date()
        let end = start.addingTimeInterval(3600) // 1 hour later

        XCTAssertTrue(calculator.isValidSlot(startAt: start, endAt: end))
    }

    func testIsValidSlot_endBeforeStart_returnsFalse() {
        let start = Date()
        let end = start.addingTimeInterval(-3600) // 1 hour earlier

        XCTAssertFalse(calculator.isValidSlot(startAt: start, endAt: end))
    }

    func testIsValidSlot_sameTime_returnsFalse() {
        let time = Date()

        XCTAssertFalse(calculator.isValidSlot(startAt: time, endAt: time))
    }

    // MARK: - Minimum Duration Tests

    func testHasMinimumDuration_exactMinimum_returnsTrue() {
        let start = Date()
        let end = start.addingTimeInterval(15 * 60) // 15 minutes
        let slot = TimeSlot(startAt: start, endAt: end)

        XCTAssertTrue(calculator.hasMinimumDuration(slot: slot, minimumMinutes: 15))
    }

    func testHasMinimumDuration_aboveMinimum_returnsTrue() {
        let start = Date()
        let end = start.addingTimeInterval(30 * 60) // 30 minutes
        let slot = TimeSlot(startAt: start, endAt: end)

        XCTAssertTrue(calculator.hasMinimumDuration(slot: slot, minimumMinutes: 15))
    }

    func testHasMinimumDuration_belowMinimum_returnsFalse() {
        let start = Date()
        let end = start.addingTimeInterval(10 * 60) // 10 minutes
        let slot = TimeSlot(startAt: start, endAt: end)

        XCTAssertFalse(calculator.hasMinimumDuration(slot: slot, minimumMinutes: 15))
    }

    // MARK: - Duration Formatting Tests

    func testFormatDuration_minutesOnly() {
        XCTAssertEqual(calculator.formatDuration(minutes: 30), "30m")
        XCTAssertEqual(calculator.formatDuration(minutes: 45), "45m")
    }

    func testFormatDuration_hoursOnly() {
        XCTAssertEqual(calculator.formatDuration(minutes: 60), "1h")
        XCTAssertEqual(calculator.formatDuration(minutes: 120), "2h")
    }

    func testFormatDuration_hoursAndMinutes() {
        XCTAssertEqual(calculator.formatDuration(minutes: 90), "1h 30m")
        XCTAssertEqual(calculator.formatDuration(minutes: 135), "2h 15m")
    }

    // MARK: - Timer Formatting Tests

    func testFormatTimer_minutesAndSeconds() {
        XCTAssertEqual(calculator.formatTimer(seconds: 0), "00:00")
        XCTAssertEqual(calculator.formatTimer(seconds: 30), "00:30")
        XCTAssertEqual(calculator.formatTimer(seconds: 90), "01:30")
        XCTAssertEqual(calculator.formatTimer(seconds: 1500), "25:00")
    }

    func testFormatTimer_withHours() {
        XCTAssertEqual(calculator.formatTimer(seconds: 3600), "1:00:00")
        XCTAssertEqual(calculator.formatTimer(seconds: 3661), "1:01:01")
    }

    // MARK: - Day Boundary Tests

    func testStartOfDay() {
        let now = Date()
        let startOfDay = calculator.startOfDay(for: now)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: startOfDay)

        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testIsSameDay_sameDay_returnsTrue() {
        let date1 = Date()
        let date2 = date1.addingTimeInterval(3600) // 1 hour later

        XCTAssertTrue(calculator.isSameDay(date1, date2))
    }

    func testIsSameDay_differentDay_returnsFalse() {
        let date1 = Date()
        let date2 = date1.addingTimeInterval(24 * 3600) // 1 day later

        XCTAssertFalse(calculator.isSameDay(date1, date2))
    }
}
