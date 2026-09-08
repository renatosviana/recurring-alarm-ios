import Foundation

enum AlertMode: String, Codable, CaseIterable {
    case sound
    case silentNotification
}

enum AlarmSchedule: Codable, Equatable {
    case oneTime(Date)
    case weekly(weekdays: Set<Int>, hour: Int, minute: Int)
    case monthly(days: Set<Int>, hour: Int, minute: Int)

    private enum CodingKeys: String, CodingKey {
        case kind, date, weekdays, days, hour, minute
    }

    private enum Kind: String, Codable {
        case oneTime, weekly, monthly
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        switch try values.decode(Kind.self, forKey: .kind) {
        case .oneTime:
            self = .oneTime(try values.decode(Date.self, forKey: .date))
        case .weekly:
            self = .weekly(
                weekdays: try values.decode(Set<Int>.self, forKey: .weekdays),
                hour: try values.decode(Int.self, forKey: .hour),
                minute: try values.decode(Int.self, forKey: .minute))
        case .monthly:
            self = .monthly(
                days: try values.decode(Set<Int>.self, forKey: .days),
                hour: try values.decode(Int.self, forKey: .hour),
                minute: try values.decode(Int.self, forKey: .minute))
        }
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .oneTime(let date):
            try values.encode(Kind.oneTime, forKey: .kind)
            try values.encode(date, forKey: .date)
        case .weekly(let weekdays, let hour, let minute):
            try values.encode(Kind.weekly, forKey: .kind)
            try values.encode(weekdays, forKey: .weekdays)
            try values.encode(hour, forKey: .hour)
            try values.encode(minute, forKey: .minute)
        case .monthly(let days, let hour, let minute):
            try values.encode(Kind.monthly, forKey: .kind)
            try values.encode(days, forKey: .days)
            try values.encode(hour, forKey: .hour)
            try values.encode(minute, forKey: .minute)
        }
    }
}

struct Alarm: Codable, Equatable, Identifiable {
    let id: UUID
    var label: String
    var mode: AlertMode
    var schedule: AlarmSchedule
    var isEnabled: Bool

    init(id: UUID = UUID(), label: String, mode: AlertMode,
         schedule: AlarmSchedule, isEnabled: Bool = true) {
        self.id = id
        self.label = label
        self.mode = mode
        self.schedule = schedule
        self.isEnabled = isEnabled
    }
}

enum AlarmValidationError: Error, Equatable {
    case invalidTime
    case emptyWeekdays
    case invalidWeekday
    case emptyMonthDays
    case invalidMonthDay
}

extension Alarm {
    func validated() throws -> Alarm {
        switch schedule {
        case .oneTime:
            return self
        case .weekly(let weekdays, let hour, let minute):
            try validateTime(hour: hour, minute: minute)
            guard !weekdays.isEmpty else { throw AlarmValidationError.emptyWeekdays }
            guard weekdays.allSatisfy({ (1...7).contains($0) }) else {
                throw AlarmValidationError.invalidWeekday
            }
        case .monthly(let days, let hour, let minute):
            try validateTime(hour: hour, minute: minute)
            guard !days.isEmpty else { throw AlarmValidationError.emptyMonthDays }
            guard days.allSatisfy({ (1...31).contains($0) }) else {
                throw AlarmValidationError.invalidMonthDay
            }
        }
        return self
    }

    private func validateTime(hour: Int, minute: Int) throws {
        guard (0...23).contains(hour), (0...59).contains(minute) else {
            throw AlarmValidationError.invalidTime
        }
    }
}
