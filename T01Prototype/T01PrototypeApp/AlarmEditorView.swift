import Foundation
import SwiftUI

struct AlarmEditorView: View {
    @ObservedObject private var store: AlarmStore
    @Environment(\.dismiss) private var dismiss
    private let onSaved: () -> Void
    private let onDeleted: () -> Void
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
    @State private var showingDeleteConfirmation = false

    enum ScheduleKind: String, CaseIterable, Identifiable {
        case oneTime = "One time"
        case weekly = "Weekly"
        case monthly = "Monthly"
        var id: String { rawValue }
    }

    init(store: AlarmStore, alarm: Alarm? = nil, onSaved: @escaping () -> Void = {},
         onDeleted: @escaping () -> Void = {}) {
        self.store = store
        self.onSaved = onSaved
        self.onDeleted = onDeleted
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
                    HStack {
                        Picker("Hour", selection: recurringHourBinding) {
                            ForEach(1...12, id: \.self) { hour in
                                Text(String(hour)).tag(hour)
                            }
                        }
                        .labelsHidden()
                        .accessibilityLabel("Hour")
                        Text(":")
                        Picker("Minute", selection: recurringMinuteBinding) {
                            ForEach(0..<60, id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .labelsHidden()
                        .accessibilityLabel("Minute")
                        Picker("Period", selection: recurringPeriodBinding) {
                            Text("AM").tag(false)
                            Text("PM").tag(true)
                        }
                        .labelsHidden()
                        .accessibilityLabel("AM or PM")
                    }
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
            if existingID != nil {
                Section {
                    Button("Delete Alarm", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
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
        .confirmationDialog("Delete this alarm?", isPresented: $showingDeleteConfirmation,
                            titleVisibility: .visible) {
            Button("Delete Alarm", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the saved alarm and cancels its pending notifications.")
        }
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
            onSaved()
            dismiss()
        } catch let error as AlarmValidationError { validationMessage = message(for: error) }
        catch { validationMessage = error.localizedDescription }
    }

    private func delete() {
        guard let existingID else { return }
        do {
            try store.remove(id: existingID)
            onDeleted()
            dismiss()
        } catch {
            validationMessage = error.localizedDescription
        }
    }

    private var recurringHour: Int {
        let hour = Calendar.current.component(.hour, from: time)
        return hour % 12 == 0 ? 12 : hour % 12
    }

    private var recurringMinute: Int {
        Calendar.current.component(.minute, from: time)
    }

    private var recurringIsPM: Bool {
        Calendar.current.component(.hour, from: time) >= 12
    }

    private var recurringHourBinding: Binding<Int> {
        Binding(get: { recurringHour }, set: { setRecurringTime(hour12: $0) })
    }

    private var recurringMinuteBinding: Binding<Int> {
        Binding(get: { recurringMinute }, set: { setRecurringTime(minute: $0) })
    }

    private var recurringPeriodBinding: Binding<Bool> {
        Binding(get: { recurringIsPM }, set: { setRecurringTime(isPM: $0) })
    }

    private func setRecurringTime(hour12: Int? = nil, minute: Int? = nil,
                                  isPM: Bool? = nil) {
        let hour = Self.hour24(hour12: hour12 ?? recurringHour,
                               isPM: isPM ?? recurringIsPM)
        time = Calendar.current.date(bySettingHour: hour,
                                     minute: minute ?? recurringMinute,
                                     second: 0, of: time) ?? time
    }

    static func hour24(hour12: Int, isPM: Bool) -> Int {
        (hour12 % 12) + (isPM ? 12 : 0)
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
