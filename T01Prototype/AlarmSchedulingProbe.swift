import Foundation
import UserNotifications

typealias PersistedAlarm = Alarm

/// The smallest scheduling probe for T01.
///
/// This deliberately uses local notifications so the recurrence shapes can be
/// inspected on an iPhone without building the rest of the product. `nil`
/// sound means that this request has no configured audio; iOS still owns the
/// decision about haptics, presentation, and duration.
struct AlarmSchedulingProbe {
    enum AlertMode: Equatable {
        case sound
        case silentNotification // No configured audio; does not request haptics.
    }

    enum Schedule {
        case oneTime(Date)
        case weekly(weekdays: Set<Int>, hour: Int, minute: Int) // 1 = Sunday
        case monthly(days: Set<Int>, hour: Int, minute: Int)
    }

    struct Alarm {
        let id: UUID
        let title: String
        let mode: AlertMode
        let schedule: Schedule
    }

    /// Plans requests for the persisted T04/T05 model without changing the
    /// recurrence rules used by the original probe.
    func requests(for alarm: PersistedAlarm, calendar: Calendar = .autoupdatingCurrent,
                  from start: Date = .now, months: Int = 12) -> [UNNotificationRequest] {
        let probeAlarm = AlarmSchedulingProbe.Alarm(
            id: alarm.id,
            title: alarm.label,
            mode: alarm.mode == .sound ? .sound : .silentNotification,
            schedule: probeSchedule(alarm.schedule))
        return requests(for: probeAlarm, calendar: calendar, from: start, months: months)
    }

    private func probeSchedule(_ schedule: AlarmSchedule) -> AlarmSchedulingProbe.Schedule {
        switch schedule {
        case .oneTime(let date):
            return .oneTime(date)
        case .weekly(let weekdays, let hour, let minute):
            return .weekly(weekdays: weekdays, hour: hour, minute: minute)
        case .monthly(let days, let hour, let minute):
            return .monthly(days: days, hour: hour, minute: minute)
        }
    }

    /// Schedules one request per occurrence for the requested number of months.
    /// Monthly dates that do not exist are skipped (for example, February 31).
    func requests(for alarm: Alarm, calendar: Calendar = .autoupdatingCurrent,
                  from start: Date = .now, months: Int = 12) -> [UNNotificationRequest] {
        let content = UNMutableNotificationContent()
        content.title = alarm.title
        content.body = "T01 scheduling probe"
        switch alarm.mode {
        case .sound:
            content.sound = .default
        case .silentNotification:
            content.sound = nil
        }

        switch alarm.schedule {
        case .oneTime(let date):
            guard date > start else { return [] }
            return [request(id: alarm.id, content: content,
                            trigger: UNCalendarNotificationTrigger(
                                dateMatching: calendar.dateComponents(
                                    [.year, .month, .day, .hour, .minute], from: date),
                                repeats: false))]

        case .weekly(let weekdays, let hour, let minute):
            return weekdays.sorted().map { weekday in
                var components = DateComponents()
                components.weekday = weekday
                components.hour = hour
                components.minute = minute
                return request(id: alarm.id, suffix: "weekly-\(weekday)", content: content,
                               trigger: UNCalendarNotificationTrigger(
                                   dateMatching: components, repeats: true))
            }

        case .monthly(let days, let hour, let minute):
            let end = calendar.date(byAdding: .month, value: months, to: start) ?? start
            var month = calendar.date(from: calendar.dateComponents([.year, .month], from: start)) ?? start
            var result: [UNNotificationRequest] = []

            while month < end {
                for day in days.sorted() {
                    var components = calendar.dateComponents([.year, .month], from: month)
                    components.day = day
                    components.hour = hour
                    components.minute = minute
                    if let occurrence = calendar.date(from: components),
                       calendar.component(.day, from: occurrence) == day,
                       calendar.component(.month, from: occurrence) == calendar.component(.month, from: month),
                       occurrence >= start, occurrence < end {
                        result.append(request(id: alarm.id,
                                              suffix: "monthly-\(occurrence.timeIntervalSince1970)",
                                              content: content,
                                              trigger: UNCalendarNotificationTrigger(
                                                  dateMatching: components, repeats: false)))
                    }
                }
                month = calendar.date(byAdding: .month, value: 1, to: month) ?? end
            }
            return result
        }
    }

    /// Investigates non-finite monthly recurrence: one repeating request per
    /// selected day. Apple documents date-component matching and repeating
    /// requests, but does not specify how an invalid day such as the 31st is
    /// handled by this trigger, so the result must be checked on-device.
    func repeatingMonthlyRequests(for alarm: Alarm) -> [UNNotificationRequest] {
        guard case .monthly(let days, let hour, let minute) = alarm.schedule else { return [] }
        let content = UNMutableNotificationContent()
        content.title = alarm.title
        content.body = "T01 repeating monthly probe"
        switch alarm.mode {
        case .sound:
            content.sound = .default
        case .silentNotification:
            content.sound = nil
        }

        return days.sorted().map { day in
            var components = DateComponents()
            components.day = day
            components.hour = hour
            components.minute = minute
            return request(id: alarm.id, suffix: "monthly-repeating-\(day)", content: content,
                           trigger: UNCalendarNotificationTrigger(
                               dateMatching: components, repeats: true))
        }
    }

    private func request(id: UUID, suffix: String = "one-time",
                         content: UNNotificationContent,
                         trigger: UNNotificationTrigger) -> UNNotificationRequest {
        UNNotificationRequest(identifier: "t01-\(id.uuidString)-\(suffix)",
                               content: content, trigger: trigger)
    }
}
