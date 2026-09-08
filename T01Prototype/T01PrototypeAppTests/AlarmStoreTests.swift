import Foundation
import XCTest
import UserNotifications
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

    func testEditingSchedulePreservesIdentityAndAlertMode() throws {
        let (defaults, key) = makeDefaults()
        let original = Alarm(label: "Payday", mode: .silentNotification,
                             schedule: .monthly(days: [1, 15], hour: 9, minute: 0))
        let store = AlarmStore(defaults: defaults, storageKey: key)
        try store.upsert(original)

        let edited = Alarm(id: original.id, label: "Payday weekly", mode: original.mode,
                           schedule: .weekly(weekdays: [2, 5], hour: 10, minute: 30))
        try store.upsert(edited)
        let reloaded = AlarmStore(defaults: defaults, storageKey: key)

        XCTAssertEqual(reloaded.alarms.count, 1)
        XCTAssertEqual(reloaded.alarms.first?.id, original.id)
        XCTAssertEqual(reloaded.alarms.first?.mode, .silentNotification)
        XCTAssertEqual(reloaded.alarms.first?.schedule,
                       .weekly(weekdays: [2, 5], hour: 10, minute: 30))
    }

    func testDeniedPermissionDoesNotAddNotification() async throws {
        let (defaults, key) = makeDefaults()
        let store = AlarmStore(defaults: defaults, storageKey: key)
        let alarm = Alarm(label: "Denied", mode: .sound,
                          schedule: .oneTime(Date(timeIntervalSinceNow: 300)))
        try store.upsert(alarm)
        let center = FakeNotificationCenter(authorized: false)
        let coordinator = AlarmSchedulingCoordinator(store: store, center: center)

        await coordinator.reconcileAll()

        XCTAssertEqual(coordinator.states[alarm.id], .permissionDenied)
        XCTAssertTrue(center.added.isEmpty)
    }

    func testEnabledSoundAndSilentAlarmsProduceOwnedRequests() async throws {
        let (defaults, key) = makeDefaults()
        let store = AlarmStore(defaults: defaults, storageKey: key)
        let sound = Alarm(label: "Sound", mode: .sound,
                          schedule: .oneTime(Date(timeIntervalSinceNow: 300)))
        let silent = Alarm(label: "Silent", mode: .silentNotification,
                           schedule: .oneTime(Date(timeIntervalSinceNow: 360)))
        try store.upsert(sound)
        try store.upsert(silent)
        let center = FakeNotificationCenter(authorized: true)
        let coordinator = AlarmSchedulingCoordinator(store: store, center: center)

        await coordinator.reconcileAll()

        XCTAssertEqual(coordinator.states[sound.id], .scheduled)
        XCTAssertEqual(coordinator.states[silent.id], .scheduled)
        XCTAssertEqual(center.added.count, 2)
        XCTAssertTrue(center.added.contains { $0.content.sound != nil })
        XCTAssertTrue(center.added.contains { $0.content.sound == nil })
    }

    func testDisabledAlarmRemovesOnlyItsOwnedRequests() async throws {
        let (defaults, key) = makeDefaults()
        let store = AlarmStore(defaults: defaults, storageKey: key)
        let disabled = Alarm(label: "Disabled", mode: .sound,
                             schedule: .oneTime(Date(timeIntervalSinceNow: 300)), isEnabled: false)
        let other = Alarm(label: "Other", mode: .sound,
                          schedule: .oneTime(Date(timeIntervalSinceNow: 360)))
        try store.upsert(disabled)
        try store.upsert(other)
        let planner = AlarmSchedulingProbe()
        let disabledRequest = planner.requests(for: disabled).first!
        let otherRequest = planner.requests(for: other).first!
        let center = FakeNotificationCenter(authorized: true, pending: [disabledRequest, otherRequest])
        let coordinator = AlarmSchedulingCoordinator(store: store, center: center)

        await coordinator.reconcile(disabled)

        XCTAssertEqual(center.removed, [disabledRequest.identifier])
        XCTAssertEqual(coordinator.states[disabled.id], .unscheduled)
        XCTAssertTrue(center.removed.contains(otherRequest.identifier) == false)
    }

    func testDeletedAlarmRemovesItsPendingRequests() async throws {
        let (defaults, key) = makeDefaults()
        let store = AlarmStore(defaults: defaults, storageKey: key)
        let deleted = Alarm(label: "Deleted", mode: .sound,
                            schedule: .oneTime(Date(timeIntervalSinceNow: 300)))
        let retained = Alarm(label: "Retained", mode: .sound,
                             schedule: .oneTime(Date(timeIntervalSinceNow: 360)))
        try store.upsert(deleted)
        try store.upsert(retained)
        let planner = AlarmSchedulingProbe()
        let deletedRequest = planner.requests(for: deleted).first!
        let retainedRequest = planner.requests(for: retained).first!
        let center = FakeNotificationCenter(authorized: true,
                                             pending: [deletedRequest, retainedRequest])
        let coordinator = AlarmSchedulingCoordinator(store: store, center: center)

        await coordinator.removeRequests(for: deleted.id)

        XCTAssertEqual(center.removed, [deletedRequest.identifier])
        XCTAssertEqual(center.pending.map(\.identifier), [retainedRequest.identifier])
        XCTAssertEqual(coordinator.states[deleted.id], .unscheduled)
    }

    func testAddFailureIsReportedAsPartialScheduling() async throws {
        let (defaults, key) = makeDefaults()
        let store = AlarmStore(defaults: defaults, storageKey: key)
        let alarm = Alarm(label: "Failure", mode: .sound,
                          schedule: .oneTime(Date(timeIntervalSinceNow: 300)))
        try store.upsert(alarm)
        let center = FakeNotificationCenter(authorized: true)
        center.shouldFailAdd = true
        let coordinator = AlarmSchedulingCoordinator(store: store, center: center)

        await coordinator.reconcile(alarm)

        guard case .partialFailure(let message) = coordinator.states[alarm.id] else {
            return XCTFail("Expected partial scheduling failure")
        }
        XCTAssertTrue(message.contains("add t01-"))
    }

    func testForegroundSoundPresentationIncludesSound() {
        let content = UNMutableNotificationContent()
        content.title = "Sound"
        content.sound = .default
        let request = UNNotificationRequest(identifier: "sound",
                                             content: content,
                                             trigger: nil)
        let notification = UNNotification(request: request, date: Date())
        var options: UNNotificationPresentationOptions = []

        NotificationPresentationDelegate.shared.userNotificationCenter(
            UNUserNotificationCenter.current(),
            willPresent: notification) { options = $0 }

        XCTAssertTrue(options.contains(.banner))
        XCTAssertTrue(options.contains(.list))
        XCTAssertTrue(options.contains(.sound))
    }

    func testForegroundSilentPresentationOmitsSound() {
        let content = UNMutableNotificationContent()
        content.title = "Silent"
        content.sound = nil
        let request = UNNotificationRequest(identifier: "silent",
                                             content: content,
                                             trigger: nil)
        let notification = UNNotification(request: request, date: Date())
        var options: UNNotificationPresentationOptions = []

        NotificationPresentationDelegate.shared.userNotificationCenter(
            UNUserNotificationCenter.current(),
            willPresent: notification) { options = $0 }

        XCTAssertTrue(options.contains(.banner))
        XCTAssertTrue(options.contains(.list))
        XCTAssertFalse(options.contains(.sound))
    }
}

private enum FakeNotificationError: Error { case addFailed }

private final class FakeNotificationCenter: NotificationSchedulingClient {
    let authorized: Bool
    var pending: [UNNotificationRequest]
    var added: [UNNotificationRequest] = []
    var removed: [String] = []
    var shouldFailAdd = false

    init(authorized: Bool, pending: [UNNotificationRequest] = []) {
        self.authorized = authorized
        self.pending = pending
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { authorized }

    func add(_ request: UNNotificationRequest) async throws {
        if shouldFailAdd { throw FakeNotificationError.addFailed }
        added.append(request)
        pending.append(request)
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] { pending }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removed.append(contentsOf: identifiers)
        pending.removeAll { identifiers.contains($0.identifier) }
    }
}
