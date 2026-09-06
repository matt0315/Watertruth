import XCTest
@testable import Watertruth

final class ScheduleEngineTests: XCTestCase {
    var engine: ScheduleEngine!
    var calendar: Calendar!
    /// Fixed "now" for deterministic tests: 2026-09-06 12:00 UTC
    var now: Date!

    override func setUp() {
        super.setUp()
        engine = ScheduleEngine()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 9
        comps.day = 6
        comps.hour = 12
        now = calendar.date(from: comps)!
    }

    // MARK: - Soil check: dry → water

    func testDrySoilWatersAndSchedulesNextInterval() {
        let due = calendar.date(byAdding: .day, value: 0, to: now)!
        let outcome = engine.applySoilCheck(
            intervalDays: 7,
            baselineIntervalDays: 7,
            scheduleMode: .adaptive,
            nextDueAt: due,
            lastWateredAt: nil,
            moisture: .dry,
            waterIfDry: true,
            now: now,
            calendar: calendar
        )
        XCTAssertTrue(outcome.didWater)
        XCTAssertEqual(outcome.eventKind, .watered)
        XCTAssertEqual(outcome.intervalDays, 7, accuracy: 0.01)
        let expected = calendar.date(byAdding: .day, value: 7, to: now)!
        XCTAssertEqual(outcome.nextDueAt, expected)
    }

    func testMoistSoilSnoozesWithoutWatering() {
        let outcome = engine.applySoilCheck(
            intervalDays: 7,
            baselineIntervalDays: 7,
            scheduleMode: .adaptive,
            nextDueAt: now,
            lastWateredAt: nil,
            moisture: .moist,
            waterIfDry: true,
            now: now,
            calendar: calendar
        )
        XCTAssertFalse(outcome.didWater)
        XCTAssertEqual(outcome.eventKind, .snoozed)
        XCTAssertEqual(outcome.snoozeDays, ScheduleEngine.moistSnoozeDays)
        XCTAssertEqual(outcome.intervalDays, 7, accuracy: 0.01)
        let expected = calendar.date(byAdding: .day, value: 2, to: now)!
        XCTAssertEqual(outcome.nextDueAt, expected)
    }

    func testWetSoilSnoozesAndLengthensAdaptiveInterval() {
        let outcome = engine.applySoilCheck(
            intervalDays: 7,
            baselineIntervalDays: 7,
            scheduleMode: .adaptive,
            nextDueAt: now,
            lastWateredAt: nil,
            moisture: .wet,
            now: now,
            calendar: calendar
        )
        XCTAssertFalse(outcome.didWater)
        XCTAssertEqual(outcome.eventKind, .snoozed)
        XCTAssertEqual(outcome.intervalDays, 7.5, accuracy: 0.01)
        let expected = calendar.date(byAdding: .day, value: 3, to: now)!
        XCTAssertEqual(outcome.nextDueAt, expected)
    }

    func testWetSoilDoesNotChangeManualInterval() {
        let outcome = engine.applySoilCheck(
            intervalDays: 7,
            baselineIntervalDays: 7,
            scheduleMode: .manual,
            nextDueAt: now,
            lastWateredAt: nil,
            moisture: .wet,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(outcome.intervalDays, 7, accuracy: 0.01)
    }

    // MARK: - Adaptive early / late

    func testWateringEarlyShortensInterval() {
        // Due in 2 days → watering early
        let due = calendar.date(byAdding: .day, value: 2, to: now)!
        let outcome = engine.applyWatering(
            intervalDays: 7,
            scheduleMode: .adaptive,
            nextDueAt: due,
            lastWateredAt: nil,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(outcome.intervalDays, 6.5, accuracy: 0.01)
        XCTAssertTrue(outcome.didWater)
    }

    func testWateringLateLengthensInterval() {
        // Was due 2 days ago
        let due = calendar.date(byAdding: .day, value: -2, to: now)!
        let outcome = engine.applyWatering(
            intervalDays: 7,
            scheduleMode: .adaptive,
            nextDueAt: due,
            lastWateredAt: nil,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(outcome.intervalDays, 7.5, accuracy: 0.01)
    }

    func testManualModeIgnoresEarlyLate() {
        let due = calendar.date(byAdding: .day, value: 2, to: now)!
        let outcome = engine.applyWatering(
            intervalDays: 7,
            scheduleMode: .manual,
            nextDueAt: due,
            lastWateredAt: nil,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(outcome.intervalDays, 7, accuracy: 0.01)
    }

    func testManualOverrideLocksInterval() {
        let result = engine.applyManualOverride(everyDays: 10, from: now, calendar: calendar)
        XCTAssertEqual(result.mode, .manual)
        XCTAssertEqual(result.intervalDays, 10, accuracy: 0.01)
        let expected = calendar.date(byAdding: .day, value: 10, to: now)!
        XCTAssertEqual(result.nextDueAt, expected)
    }

    func testIntervalClamp() {
        XCTAssertEqual(engine.clamp(1), ScheduleEngine.minIntervalDays)
        XCTAssertEqual(engine.clamp(100), ScheduleEngine.maxIntervalDays)
        XCTAssertEqual(engine.clamp(7), 7)
    }

    func testNotificationBodyNeverSaysWaterNowBare() {
        let body = NotificationService.soilCheckBody(plantName: "Monstera")
        XCTAssertEqual(body, "Check soil — Monstera")
        XCTAssertFalse(body.lowercased().hasPrefix("water now"))
        XCTAssertTrue(body.contains("Check soil"))
    }
}
