import Foundation
import SwiftUI

struct ContentView: View {
    @StateObject private var alarmStore: AlarmStore
    @StateObject private var scheduler: AlarmSchedulingCoordinator
    @State private var showingEditor = false
    @State private var errorMessage: String?

    init() {
        let store = AlarmStore()
        _alarmStore = StateObject(wrappedValue: store)
        _scheduler = StateObject(wrappedValue: AlarmSchedulingCoordinator(store: store))
    }

    var body: some View {
        NavigationStack {
            Group {
                if alarmStore.alarms.isEmpty {
                    ContentUnavailableView("No alarms", systemImage: "alarm",
                                           description: Text("Add an alarm to save and schedule it."))
                } else {
                    List {
                        ForEach(alarmStore.alarms) { alarm in
                            NavigationLink {
                                AlarmEditorView(store: alarmStore, alarm: alarm,
                                                onSaved: reconcile,
                                                onDeleted: { cleanupDeletedAlarm(alarm.id) })
                            } label: {
                                AlarmRow(alarm: alarm, state: scheduler.states[alarm.id])
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Alarms")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingEditor = true } label: {
                        Label("Add alarm", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                NavigationStack {
                    AlarmEditorView(store: alarmStore, onSaved: reconcile)
                }
            }
            .alert("Could not update alarm", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
        .task { await scheduler.reconcileAll() }
    }

    private func reconcile() {
        Task { await scheduler.reconcileAll() }
    }

    private func delete(at offsets: IndexSet) {
        do {
            let deletedIDs = offsets.map { alarmStore.alarms[$0].id }
            for id in deletedIDs { try alarmStore.remove(id: id) }
            Task {
                await cleanupDeletedAlarms(deletedIDs)
            }
        } catch { errorMessage = error.localizedDescription }
    }

    private func cleanupDeletedAlarm(_ id: UUID) {
        Task { await cleanupDeletedAlarms([id]) }
    }

    private func cleanupDeletedAlarms(_ ids: [UUID]) async {
        for id in ids { await scheduler.removeRequests(for: id) }
        await scheduler.reconcileAll()
    }
}

private struct AlarmRow: View {
    let alarm: Alarm
    let state: AlarmSchedulingState?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.label.isEmpty ? "Untitled alarm" : alarm.label).font(.headline)
                Text(alarm.schedule.summary).font(.subheadline).foregroundStyle(.secondary)
                Text(alarm.mode == .sound ? "Sound alert" : "Silent notification")
                    .font(.caption).foregroundStyle(.secondary)
                Text(statusText).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if !alarm.isEnabled { Text("Off").font(.caption).foregroundStyle(.secondary) }
        }
    }

    private var statusText: String {
        switch state {
        case .scheduled: return "Scheduled; delivery not verified"
        case .permissionDenied: return "Permission denied"
        case .partialFailure(let message): return "Partially scheduled: \(message)"
        case .failed(let message): return "Scheduling failed: \(message)"
        case .unscheduled: return "Not scheduled"
        case nil: return "Checking schedule…"
        }
    }
}

private extension AlarmSchedule {
    var summary: String {
        switch self {
        case .oneTime(let date): return date.formatted(date: .abbreviated, time: .shortened)
        case .weekly(let weekdays, let hour, let minute):
            let names = weekdays.sorted().map { Calendar.current.weekdaySymbols[$0 - 1].prefix(3) }
            return "Weekly \(names.joined(separator: ", ")) at \(String(format: "%02d:%02d", hour, minute))"
        case .monthly(let days, let hour, let minute):
            return "Monthly \(days.sorted().map(String.init).joined(separator: ", ")) at \(String(format: "%02d:%02d", hour, minute))"
        }
    }
}
