import AlarmKit
import AppIntents
import Foundation

/// Para la alarma (sonando o en snooze). Lo usan el botón Parar de la Live Activity y AlarmKit.
struct StopAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Parar alarma"
    static var openAppWhenRun = false

    @Parameter(title: "ID de alarma")
    var alarmID: String

    init() {}

    init(alarmID: UUID) {
        self.alarmID = alarmID.uuidString
    }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: alarmID) {
            try AlarmManager.shared.stop(id: id)
        }
        return .result()
    }
}
