import Foundation
import UIKit
import SwiftUI

/// Volcado de trazas + capturas para depurar con el agente (simulador o device).
/// Escribe en Documents/LecturaDumps/ (visible en Archivos) y Application Support.
@MainActor
final class TraceDump: ObservableObject {
    static let shared = TraceDump()

    struct Event: Codable {
        let ts: String
        let category: String
        let message: String
        let data: [String: String]
    }

    @Published private(set) var lastDumpFolderName: String?
    @Published private(set) var lastDumpMessage: String = ""
    @Published var banner: String?

    private var events: [Event] = []
    private let maxEvents = 800
    private var context: [String: String] = [:]
    private let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private init() {
        log("lifecycle", "TraceDump listo")
    }

    func setContext(_ key: String, _ value: String) {
        context[key] = value
        log("context", "\(key)=\(value.prefix(200))")
    }

    func log(_ category: String, _ message: String, data: [String: String] = [:]) {
        let e = Event(
            ts: iso.string(from: Date()),
            category: category,
            message: message,
            data: data
        )
        events.append(e)
        if events.count > maxEvents {
            events.removeFirst(events.count - maxEvents)
        }
        #if DEBUG
        print("[Lectura/\(category)] \(message)")
        #endif
    }

    /// Carpeta Documents/LecturaDumps (File Sharing / Archivos).
    var documentsDumpsURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("LecturaDumps", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    var supportDumpsURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Lectura/dumps", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Volcado completo: trace.jsonl, state.json, screen.png → latest/ + timestamped/.
    @discardableResult
    func dump(reason: String, extraState: [String: String] = [:]) -> URL? {
        log("dump", "Inicio volcado: \(reason)", data: extraState)
        let stamp = Self.folderStamp()
        let folderName = stamp
        let primary = documentsDumpsURL.appendingPathComponent(folderName, isDirectory: true)
        let latest = documentsDumpsURL.appendingPathComponent("latest", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: primary, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: latest.path) {
                try FileManager.default.removeItem(at: latest)
            }
            try FileManager.default.createDirectory(at: latest, withIntermediateDirectories: true)

            // state
            var state = context
            state["reason"] = reason
            state["dumpAt"] = iso.string(from: Date())
            state["device"] = UIDevice.current.model
            state["system"] = UIDevice.current.systemVersion
            state["app"] = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "Lectura"
            for (k, v) in extraState { state[k] = v }
            let stateData = try JSONSerialization.data(withJSONObject: state, options: [.prettyPrinted, .sortedKeys])
            try stateData.write(to: primary.appendingPathComponent("state.json"), options: .atomic)

            // trace.jsonl
            let enc = JSONEncoder()
            enc.outputFormatting = [.sortedKeys]
            var lines: [String] = []
            for e in events {
                if let d = try? enc.encode(e), let s = String(data: d, encoding: .utf8) {
                    lines.append(s)
                }
            }
            let jsonl = lines.joined(separator: "\n") + "\n"
            try Data(jsonl.utf8).write(to: primary.appendingPathComponent("trace.jsonl"), options: .atomic)

            // README for agent
            let readme = """
            # Lectura dump \(folderName)

            Motivo: \(reason)

            - `state.json` — contexto (libro, tab, path, errores…)
            - `trace.jsonl` — eventos recientes
            - `screen.png` — captura de pantalla

            Pull desde Mac: `apps/lector/scripts/pull-dumps.sh`
            """
            try Data(readme.utf8).write(to: primary.appendingPathComponent("README.md"), options: .atomic)

            // screenshot
            if let img = Self.captureScreenshot(), let png = img.pngData() {
                try png.write(to: primary.appendingPathComponent("screen.png"), options: .atomic)
            } else {
                log("dump", "Screenshot no disponible")
            }

            // mirror to latest + Application Support
            for name in ["state.json", "trace.jsonl", "screen.png", "README.md"] {
                let src = primary.appendingPathComponent(name)
                guard FileManager.default.fileExists(atPath: src.path) else { continue }
                try? FileManager.default.copyItem(at: src, to: latest.appendingPathComponent(name))
            }
            let supportCopy = supportDumpsURL.appendingPathComponent(folderName, isDirectory: true)
            try? FileManager.default.removeItem(at: supportCopy)
            try? FileManager.default.copyItem(at: primary, to: supportCopy)

            lastDumpFolderName = folderName
            lastDumpMessage = "Volcado \(folderName) → Archivos › Lectura › LecturaDumps"
            banner = lastDumpMessage
            log("dump", "OK \(folderName)")
            return primary
        } catch {
            lastDumpMessage = "Fallo volcado: \(error.localizedDescription)"
            banner = lastDumpMessage
            log("dump", "ERROR \(error.localizedDescription)")
            return nil
        }
    }

    private static func folderStamp() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f.string(from: Date())
    }

    private static func captureScreenshot() -> UIImage? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap(\.windows).filter(\.isKeyWindow)
        let window = windows.first ?? scenes.flatMap(\.windows).first
        guard let window else { return nil }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = window.screen.scale
        let renderer = UIGraphicsImageRenderer(size: window.bounds.size, format: format)
        return renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }
}

/// Botón + shake + banner de volcado.
struct TraceDumpChrome: ViewModifier {
    @ObservedObject private var dump = TraceDump.shared
    @State private var showCopied = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dump.dump(reason: "manual-toolbar")
                    } label: {
                        Label("Volcar", systemImage: "ladybug.fill")
                    }
                    .accessibilityIdentifier("lectura.dump")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
                dump.log("system", "Usuario hizo screenshot del sistema")
                dump.dump(reason: "system-screenshot")
            }
            .overlay(alignment: .bottom) {
                if let banner = dump.banner {
                    Text(banner)
                        .font(.caption)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .onTapGesture { dump.banner = nil }
                        .transition(.move(edge: .bottom))
                        .padding(.bottom, 8)
                        // No comerse los gestos de scroll debajo del banner.
                        .allowsHitTesting(true)
                }
            }
            .onAppear {
                // Auto-ocultar banner para no tapar scroll
                if dump.banner != nil {
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 4_000_000_000)
                        dump.banner = nil
                    }
                }
            }
            .onChange(of: dump.banner) { _, new in
                guard new != nil else { return }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 4_000_000_000)
                    if dump.banner == new { dump.banner = nil }
                }
            }
            .onShake {
                dump.dump(reason: "shake")
            }
    }
}

extension View {
    func capasTraceDumpChrome() -> some View {
        modifier(TraceDumpChrome())
    }

    func lecturaTraceDumpChrome() -> some View {
        modifier(TraceDumpChrome())
    }
}

// MARK: - Shake

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name("deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}

struct ShakeDetector: ViewModifier {
    let action: () -> Void
    func body(content: Content) -> some View {
        content.onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
            action()
        }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        modifier(ShakeDetector(action: action))
    }
}
