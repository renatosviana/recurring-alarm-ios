import Foundation
import XCTest
@testable import T01PrototypeApp

@MainActor
final class AlarmStoreTests: XCTestCase {
    private func makeDefaults() -> (UserDefaults, String) {
        let suite = "T04Tests.\(UUID().uuidString)"
        return (UserDefaults(suiteName: suite)!, suite)
    }

    func testWeeklySilentAlarmSurvivesReload() throws {
        let (defaults, key) = makeDefaults()
        let alarm = Alarm(
            label: "Morning reminder",
            mode: .silentNotification,
            schedule: .weekly(weekdays: [2, 4, 6], hour: 8, minute: 0))

        let store = AlarmStore(defaults: defaults, storageKey: key)
        try store.upsert(alarm)
        let reloaded = AlarmStore(defaults: defaults, storageKey: key)

        XCTAssertEqual(reloaded.alarms, [alarm])
        XCTAssertEqual(reloaded.alarms.first?.mode, .silentNotification)
        XCTAssertEqual(reloaded.alarms.first?.schedule,
                       .weekly(weekdays: [2, 4, 6], hour: 8, minute: 0))
    }

    func testUpsertReplacesOnlyMatchingAlarmAndDeleteIsIsolated() throws {
        let (defaults, key) = makeDefaults()
        let first = Alarm(label: "First", mode: .sound,
                          schedule: .monthly(days: [1, 15, 31], hour: 9, minute: 0))
        let second = Alarm(label: "Second", mode: .silentNotification,
                           schedule: .weekly(weekdays: [1], hour: 7, minute: 30))
        let store = AlarmStore(defaults: defaults, storageKey: key)

        try store.upsert(first)
        try store.upsert(second)
        try store.upsert(Alarm(id: first.id, label: "Updated", mode: .sound,
                               schedule: first.schedule))

        XCTAssertEqual(store.alarms.count, 2)
        XCTAssertEqual(store.alarms.first(where: { $0.id == first.id })?.label, "Updated")

        try store.remove(id: first.id)
        XCTAssertEqual(store.alarms, [second])
    }

    func testInvalidRecurrenceInputsAreRejected() throws {
        let (defaults, key) = makeDefaults()
        let store = AlarmStore(defaults: defaults, storageKey: key)

        XCTAssertThrowsError(try store.upsert(Alarm(
            label: "No weekdays", mode: .sound,
            schedule: .weekly(weekdays: [], hour: 8, minute: 0)))) { error in
            XCTAssertEqual(error as? AlarmValidationError, .emptyWeekdays)
        }
        XCTAssertThrowsError(try store.upsert(Alarm(
            label: "Invalid month day", mode: .sound,
            schedule: .monthly(days: [32], hour: 8, minute: 0)))) { error in
            XCTAssertEqual(error as? AlarmValidationError, .invalidMonthDay)
        }
        XCTAssertTrue(store.alarms.isEmpty)
    }

    func testOneTimeScheduleAndEnabledStatePersist() throws {
        let (defaults, key) = makeDefaults()
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let alarm = Alarm(label: "One time", mode: .sound,
                          schedule: .oneTime(date))
        let store = AlarmStore(defaults: defaults, storageKey: key)

        try store.upsert(alarm)
        try store.setEnabled(false, for: alarm.id)
        let reloaded = AlarmStore(defaults: defaults, storageKey: key)

        XCTAssertEqual(reloaded.alarms.first?.schedule, .oneTime(date))
        XCTAssertEqual(reloaded.alarms.first?.isEnabled, false)
    }
}
