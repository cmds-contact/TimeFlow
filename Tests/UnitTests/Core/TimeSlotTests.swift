import XCTest
@testable import TimeFlow

final class TimeSlotTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_withStartAndEnd() {
        let start = Date()
        let end = start.addingTimeInterval(3600)

        let slot = TimeSlot(startAt: start, endAt: end)

        XCTAssertEqual(slot.startAt, start)
        XCTAssertEqual(slot.endAt, end)
    }

    func testInit_withDuration() {
        let start = Date()
        let slot = TimeSlot(startAt: start, durationMinutes: 30)

        XCTAssertEqual(slot.startAt, start)
        XCTAssertEqual(slot.durationMinutes, 30)
    }

    // MARK: - Duration Tests

    func testDurationMinutes() {
        let start = Date()
        let end = start.addingTimeInterval(90 * 60) // 90 minutes

        let slot = TimeSlot(startAt: start, endAt: end)

        XCTAssertEqual(slot.durationMinutes, 90)
    }

    func testDurationHours() {
        let start = Date()
        let end = start.addingTimeInterval(90 * 60)

        let slot = TimeSlot(startAt: start, endAt: end)

        XCTAssertEqual(slot.durationHours, 1.5, accuracy: 0.01)
    }

    // MARK: - Validation Tests

    func testIsValid_validSlot_returnsTrue() {
        let start = Date()
        let end = start.addingTimeInterval(3600)

        let slot = TimeSlot(startAt: start, endAt: end)

        XCTAssertTrue(slot.isValid)
    }

    func testIsValid_invalidSlot_returnsFalse() {
        let start = Date()
        let end = start.addingTimeInterval(-3600)

        let slot = TimeSlot(startAt: start, endAt: end)

        XCTAssertFalse(slot.isValid)
    }

    // MARK: - Overlap Tests

    func testOverlaps_overlappingSlots_returnsTrue() {
        let start1 = Date()
        let end1 = start1.addingTimeInterval(2 * 3600) // 2 hours
        let slot1 = TimeSlot(startAt: start1, endAt: end1)

        let start2 = start1.addingTimeInterval(1 * 3600) // 1 hour after start1
        let end2 = start2.addingTimeInterval(2 * 3600)
        let slot2 = TimeSlot(startAt: start2, endAt: end2)

        XCTAssertTrue(slot1.overlaps(with: slot2))
        XCTAssertTrue(slot2.overlaps(with: slot1))
    }

    func testOverlaps_adjacentSlots_returnsFalse() {
        let start1 = Date()
        let end1 = start1.addingTimeInterval(1 * 3600)
        let slot1 = TimeSlot(startAt: start1, endAt: end1)

        let start2 = end1 // Starts exactly when slot1 ends
        let end2 = start2.addingTimeInterval(1 * 3600)
        let slot2 = TimeSlot(startAt: start2, endAt: end2)

        XCTAssertFalse(slot1.overlaps(with: slot2))
    }

    func testOverlaps_nonOverlappingSlots_returnsFalse() {
        let start1 = Date()
        let end1 = start1.addingTimeInterval(1 * 3600)
        let slot1 = TimeSlot(startAt: start1, endAt: end1)

        let start2 = end1.addingTimeInterval(1 * 3600) // 1 hour gap
        let end2 = start2.addingTimeInterval(1 * 3600)
        let slot2 = TimeSlot(startAt: start2, endAt: end2)

        XCTAssertFalse(slot1.overlaps(with: slot2))
    }

    // MARK: - Contains Tests

    func testContainsDate_dateInSlot_returnsTrue() {
        let start = Date()
        let end = start.addingTimeInterval(2 * 3600)
        let slot = TimeSlot(startAt: start, endAt: end)

        let middle = start.addingTimeInterval(1 * 3600)

        XCTAssertTrue(slot.contains(middle))
    }

    func testContainsDate_dateOutsideSlot_returnsFalse() {
        let start = Date()
        let end = start.addingTimeInterval(2 * 3600)
        let slot = TimeSlot(startAt: start, endAt: end)

        let before = start.addingTimeInterval(-1 * 3600)
        let after = end.addingTimeInterval(1 * 3600)

        XCTAssertFalse(slot.contains(before))
        XCTAssertFalse(slot.contains(after))
    }

    // MARK: - Intersection Tests

    func testIntersection_overlappingSlots_returnsIntersection() {
        let start1 = Date()
        let end1 = start1.addingTimeInterval(2 * 3600)
        let slot1 = TimeSlot(startAt: start1, endAt: end1)

        let start2 = start1.addingTimeInterval(1 * 3600)
        let end2 = start2.addingTimeInterval(2 * 3600)
        let slot2 = TimeSlot(startAt: start2, endAt: end2)

        let intersection = slot1.intersection(with: slot2)

        XCTAssertNotNil(intersection)
        XCTAssertEqual(intersection?.startAt, start2)
        XCTAssertEqual(intersection?.endAt, end1)
    }

    func testIntersection_nonOverlappingSlots_returnsNil() {
        let start1 = Date()
        let end1 = start1.addingTimeInterval(1 * 3600)
        let slot1 = TimeSlot(startAt: start1, endAt: end1)

        let start2 = end1.addingTimeInterval(1 * 3600)
        let end2 = start2.addingTimeInterval(1 * 3600)
        let slot2 = TimeSlot(startAt: start2, endAt: end2)

        XCTAssertNil(slot1.intersection(with: slot2))
    }

    // MARK: - Move Tests

    func testMoved_positiveInterval() {
        let start = Date()
        let end = start.addingTimeInterval(1 * 3600)
        let slot = TimeSlot(startAt: start, endAt: end)

        let moved = slot.moved(by: 30 * 60) // 30 minutes

        XCTAssertEqual(moved.startAt, start.addingTimeInterval(30 * 60))
        XCTAssertEqual(moved.endAt, end.addingTimeInterval(30 * 60))
        XCTAssertEqual(moved.durationMinutes, slot.durationMinutes)
    }

    // MARK: - Rounding Tests

    func testRounded_toFifteenMinutes() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 7
        let start = calendar.date(from: components)!

        components.minute = 37
        let end = calendar.date(from: components)!

        let slot = TimeSlot(startAt: start, endAt: end)
        let rounded = slot.rounded(toMinutes: 15)

        let startComponents = calendar.dateComponents([.minute], from: rounded.startAt)
        let endComponents = calendar.dateComponents([.minute], from: rounded.endAt)

        // 7 rounds to 0, 37 rounds to 30 or 45
        XCTAssertEqual(startComponents.minute! % 15, 0)
        XCTAssertEqual(endComponents.minute! % 15, 0)
    }
}
