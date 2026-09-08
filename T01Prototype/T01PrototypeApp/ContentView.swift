import Foundation
import SwiftUI

struct ContentView: View {
    @StateObject private var alarmStore = AlarmStore()
    @State private var showingEditor = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if alarmStore.alarms.isEmpty {
                    ContentUnavailableView("No alarms", systemImage: "alarm",
                                           description: Text("Add an alarm to save its schedule locally."))
                } else {
                    List {
                        ForEach(alarmStore.alarms) { alarm in
                            NavigationLink {
                                AlarmEditorView(store: alarmStore, alarm: alarm)
                            } label: {
                                AlarmRow(alarm: alarm)
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
                NavigationStack { AlarmEditorView(store: alarmStore) }
            }
            .alert("Could not update alarm", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        do {
            for index in offsets { try alarmStore.remove(id: alarmStore.alarms[index].id) }
        } catch { errorMessage = error.localizedDescription }
    }
}

private struct AlarmRow: View {
    let alarm: Alarm

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.label.isEmpty ? "Untitled alarm" : alarm.label).font(.headline)
                Text(alarm.schedule.summary).font(.subheadline).foregroundStyle(.secondary)
                Text(alarm.mode == .sound ? "Sound alert" : "Silent notification")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !alarm.isEnabled { Text("Off").font(.caption).foregroundStyle(.secondary) }
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
