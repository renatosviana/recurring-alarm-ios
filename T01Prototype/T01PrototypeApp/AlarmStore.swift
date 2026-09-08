import Foundation
import Combine

@MainActor
final class AlarmStore: ObservableObject {
    @Published private(set) var alarms: [Alarm]

    private let defaults: UserDefaults
    private let storageKey: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard,
         storageKey: String = "recurring-alarm.configurations") {
        self.defaults = defaults
        self.storageKey = storageKey
        if let data = defaults.data(forKey: storageKey),
           let saved = try? decoder.decode([Alarm].self, from: data) {
            alarms = saved
        } else {
            alarms = []
        }
    }

    func upsert(_ alarm: Alarm) throws {
        let alarm = try alarm.validated()
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
        } else {
            alarms.append(alarm)
        }
        try persist()
    }

    func remove(id: UUID) throws {
        alarms.removeAll { $0.id == id }
        try persist()
    }

    func setEnabled(_ enabled: Bool, for id: UUID) throws {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        alarms[index].isEnabled = enabled
        try persist()
    }

    private func persist() throws {
        defaults.set(try encoder.encode(alarms), forKey: storageKey)
    }
}
