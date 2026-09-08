import Foundation
import SwiftUI

struct AlarmEditorView: View {
    @ObservedObject private var store: AlarmStore
    @Environment(\.dismiss) private var dismiss
    private let existingID: UUID?
    @State private var label: String
    @State private var mode: AlertMode
    @State private var kind: ScheduleKind
    @State private var oneTimeDate: Date
    @State private var time: Date
    @State private var weekdays: Set<Int>
    @State private var monthDays: Set<Int>
    @State private var isEnabled: Bool
    @State private var validationMessage: String?

    enum ScheduleKind: String, CaseIterable, Identifiable {
        case oneTime = "One time"
        case weekly = "Weekly"
        case monthly = "Monthly"
        var id: String { rawValue }
    }

    init(store: AlarmStore, alarm: Alarm? = nil) {
        self.store = store
        existingID = alarm?.id
        _label = State(initialValue: alarm?.label ?? "")
        _mode = State(initialValue: alarm?.mode ?? .sound)
        _isEnabled = State(initialValue: alarm?.isEnabled ?? true)
        let now = Date()
        let defaultTime = Calendar.current.date(byAdding: .minute, value: 5, to: now) ?? now
        switch alarm?.schedule {
        case .oneTime(let date):
            _kind = State(initialValue: .oneTime); _oneTimeDate = State(initialValue: date); _time = State(initialValue: date)
            _weekdays = State(initialValue: []); _monthDays = State(initialValue: [])
        case .weekly(let days, let hour, let minute):
            _kind = State(initialValue: .weekly); _oneTimeDate = State(initialValue: defaultTime)
            _time = State(initialValue: Self.date(hour: hour, minute: minute)); _weekdays = State(initialValue: days); _monthDays = State(initialValue: [])
        case .monthly(let days, let hour, let minute):
            _kind = State(initialValue: .monthly); _oneTimeDate = State(initialValue: defaultTime)
            _time = State(initialValue: Self.date(hour: hour, minute: minute)); _weekdays = State(initialValue: []); _monthDays = State(initialValue: days)
        case nil:
            _kind = State(initialValue: .oneTime); _oneTimeDate = State(initialValue: defaultTime); _time = State(initialValue: defaultTime)
            _weekdays = State(initialValue: []); _monthDays = State(initialValue: [])
        }
    }

    var body: some View {
        Form {
            Section("Alarm") {
                TextField("Label", text: $label)
                Picker("Alert", selection: $mode) {
                    Text("Sound alert").tag(AlertMode.sound)
                    Text("Silent notification").tag(AlertMode.silentNotification)
                }
                Toggle("Enabled", isOn: $isEnabled)
                Text("Silent notifications configure no sound and do not guarantee vibration.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Schedule") {
                Picker("Repeats", selection: $kind) {
                    ForEach(ScheduleKind.allCases) { value in Text(value.rawValue).tag(value) }
                }
                if kind == .oneTime {
                    DatePicker("Date and time", selection: $oneTimeDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                } else {
                    DatePicker("Time", selection: $time, displayedComponents: [.hourAndMinute])
                }
            }
            if kind == .weekly {
                Section("Weekdays") {
                    ForEach(1...7, id: \.self) { weekday in
                        Toggle(Calendar.current.weekdaySymbols[weekday - 1], isOn: weekdayBinding(weekday))
                    }
                }
            }
            if kind == .monthly {
                Section("Days of month") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                        ForEach(1...31, id: \.self) { day in
                            Button { toggleMonthDay(day) } label: {
                                Text(String(day)).frame(maxWidth: .infinity, minHeight: 32)
                                    .background(monthDays.contains(day) ? Color.accentColor : Color.clear)
                                    .foregroundStyle(monthDays.contains(day) ? .white : .primary).clipShape(Circle())
                            }.buttonStyle(.plain)
                        }
                    }
                    Text("Invalid dates such as the 31st are skipped in months that do not contain them.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(existingID == nil ? "New alarm" : "Edit alarm")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
        }
        .alert("Invalid alarm", isPresented: Binding(
            get: { validationMessage != nil }, set: { if !$0 { validationMessage = nil } })) {
            Button("OK") { validationMessage = nil }
        } message: { Text(validationMessage ?? "Check the alarm values.") }
    }

    private func save() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let schedule: AlarmSchedule
        switch kind {
        case .oneTime: schedule = .oneTime(oneTimeDate)
        case .weekly: schedule = .weekly(weekdays: weekdays, hour: components.hour ?? 0, minute: components.minute ?? 0)
        case .monthly: schedule = .monthly(days: monthDays, hour: components.hour ?? 0, minute: components.minute ?? 0)
        }
        do {
            try store.upsert(Alarm(id: existingID ?? UUID(), label: label, mode: mode, schedule: schedule, isEnabled: isEnabled))
            dismiss()
        } catch let error as AlarmValidationError { validationMessage = message(for: error) }
        catch { validationMessage = error.localizedDescription }
    }

    private func weekdayBinding(_ weekday: Int) -> Binding<Bool> {
        Binding(get: { weekdays.contains(weekday) }, set: { if $0 { weekdays.insert(weekday) } else { weekdays.remove(weekday) } })
    }

    private func toggleMonthDay(_ day: Int) {
        if monthDays.contains(day) { monthDays.remove(day) } else { monthDays.insert(day) }
    }

    private func message(for error: AlarmValidationError) -> String {
        switch error {
        case .invalidTime: return "Choose a valid time."
        case .emptyWeekdays: return "Select at least one weekday."
        case .invalidWeekday: return "Choose valid weekdays."
        case .emptyMonthDays: return "Select at least one day of the month."
        case .invalidMonthDay: return "Choose days from 1 through 31."
        }
    }

    private static func date(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
}
