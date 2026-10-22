import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

struct AlarmLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<WakeAlarmMetadata>.self) { context in
            lockScreen(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "alarm.fill")
                        .foregroundStyle(context.attributes.tintColor)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdownText(state: context.state)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.metadata?.label ?? "Alarma")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    stopButton(state: context.state)
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(context.attributes.tintColor)
            } compactTrailing: {
                countdownText(state: context.state)
                    .frame(width: 44)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(context.attributes.tintColor)
            }
            .keylineTint(context.attributes.tintColor)
        }
    }

    @ViewBuilder
    private func lockScreen(context: ActivityViewContext<AlarmAttributes<WakeAlarmMetadata>>) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "moon.zzz.fill")
                .font(.title)
                .foregroundStyle(context.attributes.tintColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.metadata?.label ?? "Alarma")
                    .font(.headline)
                Text(modeLabel(context.state))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            countdownText(state: context.state)
                .font(.title2.monospacedDigit().weight(.bold))

            stopButton(state: context.state)
        }
        .padding(16)
        .activityBackgroundTint(Color.black.opacity(0.35))
    }

    private func stopButton(state: AlarmPresentationState) -> some View {
        Button(intent: StopAlarmIntent(alarmID: state.alarmID)) {
            Label("Parar", systemImage: "stop.fill")
                .font(.headline)
                .padding(.horizontal, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
    }

    @ViewBuilder
    private func countdownText(state: AlarmPresentationState) -> some View {
        switch state.mode {
        case .countdown(let info):
            Text(info.fireDate, style: .timer)
        case .paused(let info):
            let remaining = info.totalCountdownDuration - info.previouslyElapsedDuration
            Text(Duration.seconds(remaining), format: .time(pattern: .minuteSecond))
        case .alert:
            Text("¡YA!")
        @unknown default:
            Text("--:--")
        }
    }

    private func modeLabel(_ state: AlarmPresentationState) -> String {
        switch state.mode {
        case .countdown:
            return "Snooze"
        case .paused:
            return "Pausado"
        case .alert:
            return "Sonando"
        @unknown default:
            return ""
        }
    }
}
