import AlarmKit
import Foundation

/// Metadata compartida entre la app y el widget de Live Activity (snooze).
struct WakeAlarmMetadata: AlarmMetadata {
    var label: String
}
