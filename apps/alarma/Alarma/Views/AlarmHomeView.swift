import SwiftUI

struct AlarmHomeView: View {
    @EnvironmentObject private var store: AlarmStore

    var body: some View {
        ZStack {
            background

            VStack(spacing: 36) {
                Text("Alarma")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                if store.isRingingOrSnoozing {
                    stopButton
                }

                timePicker

                Toggle(isOn: Binding(
                    get: { store.isEnabled },
                    set: { newValue in
                        Task { await store.setEnabled(newValue) }
                    }
                )) {
                    Text(store.isEnabled ? "Activada" : "Activar")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                }
                .toggleStyle(.switch)
                .scaleEffect(1.4)
                .padding(.horizontal, 48)

                snoozeControl

                if let status = store.statusMessage {
                    Text(status)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if store.authorizationState == .denied {
                    Text("Permiso denegado. Ajustes → Alarma → Alarmas.")
                        .font(.body)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                if let error = store.errorMessage {
                    Text(error)
                        .font(.body)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 12)

                Button {
                    Task { await store.testRingInTenSeconds() }
                } label: {
                    Text("Probar en 10 s")
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .padding(.horizontal, 40)

                Text("Al sonar: desliza para parar o pulsa Snooze. En snooze, Parar en la pantalla bloqueada.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 24)
            }
            .padding(40)
            .frame(maxWidth: 720)
        }
        .task {
            store.start()
            if store.authorizationState == .notDetermined {
                await store.requestAuthorization()
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.09, blue: 0.14),
                Color(red: 0.14, green: 0.12, blue: 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var timePicker: some View {
        HStack(spacing: 8) {
            Picker("Hora", selection: $store.hour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d", h)).tag(h)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: 160)
            .clipped()

            Text(":")
                .font(.system(size: 64, weight: .bold, design: .rounded))

            Picker("Minuto", selection: $store.minute) {
                ForEach(0..<60, id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: 160)
            .clipped()
        }
        .font(.system(size: 44, weight: .semibold, design: .rounded))
        .onChange(of: store.hour) { _, _ in
            Task { await store.applyTimeChange() }
        }
        .onChange(of: store.minute) { _, _ in
            Task { await store.applyTimeChange() }
        }
    }

    private var stopButton: some View {
        Button {
            store.stopRinging()
        } label: {
            Label("PARAR", systemImage: "stop.fill")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .padding(.horizontal, 40)
    }

    private var snoozeControl: some View {
        VStack(spacing: 12) {
            Text("Snooze")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 28) {
                Button {
                    store.snoozeMinutes = max(1, store.snoozeMinutes - 1)
                    Task { await store.applySnoozeChange() }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 44))
                }

                Text("\(store.snoozeMinutes) min")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .frame(minWidth: 120)

                Button {
                    store.snoozeMinutes = min(30, store.snoozeMinutes + 1)
                    Task { await store.applySnoozeChange() }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                }
            }
            .tint(.orange)
        }
    }
}

#Preview {
    AlarmHomeView()
        .environmentObject(AlarmStore())
}
