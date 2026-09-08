import Foundation
import Combine
import UserNotifications

enum AlarmSchedulingState: Equatable {
    case unscheduled
    case scheduled
    case permissionDenied
    case partialFailure(String)
    case failed(String)
}

protocol NotificationSchedulingClient {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func pendingNotificationRequests() async -> [UNNotificationRequest]
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: NotificationSchedulingClient {}

@MainActor
final class AlarmSchedulingCoordinator: ObservableObject {
    @Published private(set) var states: [UUID: AlarmSchedulingState] = [:]

    private let store: AlarmStore
    private let center: NotificationSchedulingClient
    private let planner: AlarmSchedulingProbe

    init(store: AlarmStore, center: NotificationSchedulingClient = UNUserNotificationCenter.current(),
         planner: AlarmSchedulingProbe = AlarmSchedulingProbe()) {
        self.store = store
        self.center = center
        self.planner = planner
    }

    func reconcileAll() async {
        for alarm in store.alarms {
            await reconcile(alarm)
        }
    }

    func reconcile(_ alarm: Alarm) async {
        let pending = await center.pendingNotificationRequests()
        let owned = pending.filter { owns($0.identifier, alarmID: alarm.id) }

        guard alarm.isEnabled else {
            center.removePendingNotificationRequests(withIdentifiers: owned.map(\.identifier))
            states[alarm.id] = .unscheduled
            return
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                states[alarm.id] = .permissionDenied
                return
            }

            let desired = planner.requests(for: alarm)
            let existingIDs = Set(owned.map(\.identifier))
            let desiredIDs = Set(desired.map(\.identifier))
            if desired.isEmpty {
                if !existingIDs.isEmpty {
                    center.removePendingNotificationRequests(withIdentifiers: Array(existingIDs))
                }
                states[alarm.id] = .unscheduled
                return
            }
            let missing = desired.filter { !existingIDs.contains($0.identifier) }
            let obsolete = existingIDs.subtracting(desiredIDs)
            var failures: [String] = []

            for request in missing {
                do {
                    try await center.add(request)
                } catch {
                    failures.append("add \(request.identifier): \(error.localizedDescription)")
                }
            }
            if !obsolete.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: Array(obsolete))
            }

            states[alarm.id] = failures.isEmpty
                ? .scheduled
                : .partialFailure(failures.joined(separator: "; "))
        } catch {
            states[alarm.id] = .failed(error.localizedDescription)
        }
    }

    func removeRequests(for alarmID: UUID) async {
        let pending = await center.pendingNotificationRequests()
        let owned = pending.filter { owns($0.identifier, alarmID: alarmID) }
        center.removePendingNotificationRequests(withIdentifiers: owned.map(\.identifier))
        states[alarmID] = .unscheduled
    }

    private func owns(_ identifier: String, alarmID: UUID) -> Bool {
        identifier.hasPrefix("t01-\(alarmID.uuidString)-")
    }
}
