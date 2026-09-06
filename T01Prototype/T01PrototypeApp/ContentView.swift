import SwiftUI
import UserNotifications

struct ContentView: View {
    private let center = UNUserNotificationCenter.current()
    private let probe = AlarmSchedulingProbe()
    @State private var status = "No probe requests scheduled yet."

    var body: some View {
        NavigationStack {
            Form {
                Section("Alert modes") {
                    Button("Schedule sound alarm (2 minutes)") {
                        scheduleOneTime(mode: .sound)
                    }
                    Button("Schedule no-sound alarm (2 minutes)") {
                        scheduleOneTime(mode: .vibrationOnly)
                    }
                    Text("No-sound is not a vibration-only guarantee. iOS controls haptics and presentation.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Recurrence") {
                    Button("Schedule Monday / Wednesday / Friday") {
                        scheduleWeekly()
                    }
                    Button("Schedule monthly 1st / 15th / 31st") {
                        scheduleMonthly()
                    }
                    Button("Schedule repeating monthly 1st / 15th / 31st") {
                        scheduleMonthlyRepeating()
                    }
                    Text("The first monthly button uses a finite 12-month set. The second tests repeating day-of-month triggers directly.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Inspection") {
                    Button("Count pending probe requests") {
                        inspectPending()
                    }
                    Button("Cancel all probe requests", role: .destructive) {
                        center.removeAllPendingNotificationRequests()
                        status = "Cancelled all pending probe requests."
                    }
                    Text(status)
                        .font(.footnote)
                }
            }
            .navigationTitle("T01 Alarm Probe")
        }
    }

    private func scheduleOneTime(mode: AlarmSchedulingProbe.AlertMode) {
        schedule(AlarmSchedulingProbe.Schedule.oneTime(
            Date(timeIntervalSinceNow: 120)), mode: mode)
    }

    private func scheduleWeekly() {
        let time = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: Date())
        schedule(.weekly(weekdays: [2, 4, 6], hour: time.hour ?? 9, minute: time.minute ?? 0),
                 mode: .sound)
    }

    private func scheduleMonthly() {
        let time = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: Date())
        schedule(.monthly(days: [1, 15, 31], hour: time.hour ?? 9, minute: time.minute ?? 0),
                 mode: .sound)
    }

    private func scheduleMonthlyRepeating() {
        let time = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: Date())
        let alarm = AlarmSchedulingProbe.Alarm(
            id: UUID(), title: "T01 repeating monthly probe", mode: .sound,
            schedule: .monthly(days: [1, 15, 31], hour: time.hour ?? 9, minute: time.minute ?? 0))
        schedule(requests: probe.repeatingMonthlyRequests(for: alarm))
    }

    private func schedule(_ schedule: AlarmSchedulingProbe.Schedule,
                          mode: AlarmSchedulingProbe.AlertMode) {
        Task { @MainActor in
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                guard granted else {
                    status = "Notification permission was not granted."
                    return
                }

                let alarm = AlarmSchedulingProbe.Alarm(
                    id: UUID(), title: "T01 probe", mode: mode, schedule: schedule)
                let requests = probe.requests(for: alarm)
                try await add(requests)
            } catch {
                status = "Scheduling failed: \(error.localizedDescription)"
            }
        }
    }

    private func schedule(requests: [UNNotificationRequest]) {
        Task { @MainActor in
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                guard granted else {
                    status = "Notification permission was not granted."
                    return
                }
                try await add(requests)
            } catch {
                status = "Scheduling failed: \(error.localizedDescription)"
            }
        }
    }

    private func add(_ requests: [UNNotificationRequest]) async throws {
        for request in requests {
            try await center.add(request)
        }
        status = "Added \(requests.count) notification request(s)."
    }

    private func inspectPending() {
        Task { @MainActor in
            let requests = await center.pendingNotificationRequests()
            let probeRequests = requests.filter { $0.identifier.hasPrefix("t01-") }
            status = "Pending probe requests: \(probeRequests.count) (all app requests: \(requests.count))."
        }
    }
}
