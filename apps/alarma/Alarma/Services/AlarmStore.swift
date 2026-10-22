import AlarmKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class AlarmStore: ObservableObject {
    private let manager = AlarmManager.shared

    @Published var hour: Int = 7
    @Published var minute: Int = 0
    @Published var snoozeMinutes: Int = 5
    @Published var isEnabled: Bool = false
    @Published var authorizationState: AlarmManager.AuthorizationState = .notDetermined
    @Published var activeAlarmID: UUID?
    @Published var alarmState: Alarm.State?
    @Published var statusMessage: String?
    @Published var errorMessage: String?

    private let defaults = UserDefaults.standard
    private let hourKey = "alarma.hour"
    private let minuteKey = "alarma.minute"
    private let snoozeKey = "alarma.snoozeMinutes"
    private let enabledKey = "alarma.enabled"
    private let idKey = "alarma.activeID"

    init() {
        hour = defaults.object(forKey: hourKey) as? Int ?? 7
        minute = defaults.object(forKey: minuteKey) as? Int ?? 0
        snoozeMinutes = defaults.object(forKey: snoozeKey) as? Int ?? 5
        isEnabled = defaults.bool(forKey: enabledKey)
        if let raw = defaults.string(forKey: idKey), let id = UUID(uuidString: raw) {
            activeAlarmID = id
        }
        authorizationState = manager.authorizationState
    }

    func start() {
        Task {
            await observeAuthorization()
        }
        Task {
            await observeAlarms()
        }
        Task {
            await restoreIfNeeded()
        }
    }

    func requestAuthorization() async {
        do {
            authorizationState = try await manager.requestAuthorization()
            if authorizationState == .denied {
                errorMessage = "Activa Alarmas en Ajustes → Alarma."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setEnabled(_ enabled: Bool) async {
        errorMessage = nil
        if enabled {
            await activateAlarm()
        } else {
            await deactivateAlarm()
        }
    }

    func applyTimeChange() async {
        guard isEnabled else {
            persistPrefs()
            return
        }
        await activateAlarm()
    }

    func applySnoozeChange() async {
        persistPrefs()
        guard isEnabled else { return }
        await activateAlarm()
    }

    /// Programa un aviso en ~10 s para probar Parar / Snooze en pantalla bloqueada.
    func testRingInTenSeconds() async {
        errorMessage = nil
        statusMessage = nil

        guard await ensureAuthorized() else { return }

        if let id = activeAlarmID {
            try? manager.cancel(id: id)
        }

        let id = UUID()
        do {
            let config = try makeConfiguration(
                id: id,
                schedule: nil,
                countdown: Alarm.CountdownDuration(preAlert: 10, postAlert: TimeInterval(snoozeMinutes * 60)),
                label: "Prueba"
            )
            _ = try await manager.schedule(id: id, configuration: config)
            activeAlarmID = id
            isEnabled = false
            persistPrefs()
            statusMessage = "Suena en 10 s. Bloquea el iPad para ver Parar y Snooze."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Para la alarma que suena o está en snooze. Si es diaria, queda programada para mañana.
    func stopRinging() {
        guard let id = activeAlarmID else { return }
        do {
            try manager.stop(id: id)
            statusMessage = isEnabled ? "Parada · vuelve mañana a las \(formattedTime)" : "Parada"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var isRingingOrSnoozing: Bool {
        switch alarmState {
        case .alerting, .countdown, .paused: return true
        default: return false
        }
    }

    // MARK: - Private

    private func activateAlarm() async {
        guard await ensureAuthorized() else {
            isEnabled = false
            persistPrefs()
            return
        }

        if let id = activeAlarmID {
            try? manager.cancel(id: id)
        }

        let id = UUID()
        let schedule = Alarm.Schedule.relative(
            .init(
                time: .init(hour: hour, minute: minute),
                repeats: .weekly([.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday])
            )
        )

        do {
            let config = try makeConfiguration(
                id: id,
                schedule: schedule,
                countdown: Alarm.CountdownDuration(
                    preAlert: nil,
                    postAlert: TimeInterval(snoozeMinutes * 60)
                ),
                label: "Despertador"
            )
            _ = try await manager.schedule(id: id, configuration: config)
            activeAlarmID = id
            isEnabled = true
            statusMessage = "Activa · \(formattedTime) · snooze \(snoozeMinutes) min"
            persistPrefs()
        } catch {
            isEnabled = false
            errorMessage = error.localizedDescription
            persistPrefs()
        }
    }

    private func deactivateAlarm() async {
        if let id = activeAlarmID {
            try? manager.cancel(id: id)
        }
        activeAlarmID = nil
        alarmState = nil
        isEnabled = false
        statusMessage = "Apagada"
        persistPrefs()
    }

    private func ensureAuthorized() async -> Bool {
        if authorizationState == .authorized { return true }
        await requestAuthorization()
        return authorizationState == .authorized
    }

    private func makeConfiguration(
        id: UUID,
        schedule: Alarm.Schedule?,
        countdown: Alarm.CountdownDuration?,
        label: String
    ) throws -> AlarmManager.AlarmConfiguration<WakeAlarmMetadata> {
        let snooze = AlarmButton(
            text: "Snooze",
            textColor: .white,
            systemImageName: "moon.zzz.fill"
        )

        // Desde iPadOS 26.1 el botón de parar lo dibuja el sistema (deslizar); solo el secundario es nuestro.
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: "\(label) · desliza para parar"),
            secondaryButton: snooze,
            secondaryButtonBehavior: .countdown
        )

        let countdownUI = AlarmPresentation.Countdown(
            title: LocalizedStringResource(stringLiteral: "Snooze…")
        )

        let presentation = AlarmPresentation(alert: alert, countdown: countdownUI)
        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: WakeAlarmMetadata(label: label),
            tintColor: Color.orange
        )

        return AlarmManager.AlarmConfiguration(
            countdownDuration: countdown,
            schedule: schedule,
            attributes: attributes,
            stopIntent: StopAlarmIntent(alarmID: id),
            sound: .named("arpa.caf")
        )
    }

    private func restoreIfNeeded() async {
        authorizationState = manager.authorizationState
        do {
            let alarms = try manager.alarms
            if let id = activeAlarmID, let match = alarms.first(where: { $0.id == id }) {
                alarmState = match.state
                isEnabled = true
                statusMessage = "Activa · \(formattedTime)"
            } else if isEnabled {
                // Preferencia decía ON pero el sistema no tiene la alarma → reprogramar
                await activateAlarm()
            }
        } catch {
            // Sin alarmas aún
        }
    }

    private func observeAuthorization() async {
        for await state in manager.authorizationUpdates {
            authorizationState = state
        }
    }

    private func observeAlarms() async {
        for await alarms in manager.alarmUpdates {
            if let id = activeAlarmID, let match = alarms.first(where: { $0.id == id }) {
                alarmState = match.state
            } else if activeAlarmID != nil, !alarms.contains(where: { $0.id == activeAlarmID }) {
                // Alarma one-shot / prueba terminada
                if !isEnabled {
                    activeAlarmID = nil
                    alarmState = nil
                    persistPrefs()
                }
            }
        }
    }

    private func persistPrefs() {
        defaults.set(hour, forKey: hourKey)
        defaults.set(minute, forKey: minuteKey)
        defaults.set(snoozeMinutes, forKey: snoozeKey)
        defaults.set(isEnabled, forKey: enabledKey)
        defaults.set(activeAlarmID?.uuidString, forKey: idKey)
    }

    var formattedTime: String {
        String(format: "%02d:%02d", hour, minute)
    }
}
