// Barra Superior — a strip at the top of each screen that is there while the macOS menu bar is
// hidden (auto-hide or full screen) and gets out of the way the moment the menu bar slides in.
//
// It shows the active timers of Timers Paralelos PRO and the Claude/Cursor sessions of Tablero IA.
// Both apps write a small JSON for it; this app only reads:
//
//   ~/Library/Application Support/Timers Paralelos PRO/active-timers.json   (on every change)
//   ~/.claude/tablero-ia/barra.json                                        (every 5 s)
//
// How it knows the menu bar is showing: the Window Server owns one "Menubar" window per screen at
// the main-menu level. While hidden it sits off screen (y = -30) and drops out of the on-screen
// window list; when it slides in it comes back with y going -27 → -8 → 0. Polled at ~12 Hz, which
// costs about 1 ms a call.
import AppKit
import ServiceManagement
import SwiftUI

// Launched from a Cursor/VS Code terminal this would inherit ELECTRON_RUN_AS_NODE and hand it to
// the Electron apps we open, which then start as plain Node and show nothing.
unsetenv("ELECTRON_RUN_AS_NODE")

let home = FileManager.default.homeDirectoryForCurrentUser
let timersFile = home.appendingPathComponent("Library/Application Support/Timers Paralelos PRO/active-timers.json")
let tableroFile = home.appendingPathComponent(".claude/tablero-ia/barra.json")
let timersApp = URL(fileURLWithPath: "/Applications/Timers Paralelos PRO.app")
let tableroApp = URL(fileURLWithPath: "/Applications/Tablero IA.app")

// MARK: - Data

struct ActiveTimer: Decodable, Identifiable {
  let id: String
  let label: String
  let color: String
  let state: String          // running | paused | waiting
  let endTime: Double?       // ms since 1970, running only
  let remainingMs: Double?   // paused and waiting

  func remaining(_ now: Date) -> Double {
    if state == "running", let end = endTime { return max(0, end / 1000 - now.timeIntervalSince1970) }
    return (remainingMs ?? 0) / 1000
  }
}
struct TimersSnapshot: Decodable { let pid: Int32; let timers: [ActiveTimer] }
struct TableroSnapshot: Decodable {
  let at: Double
  let pid: Int32
  let working: Int
  let waiting: Int
  let permission: Int
  let memMB: Int
}

func alive(_ pid: Int32) -> Bool { kill(pid, 0) == 0 || errno == EPERM }
func load<T: Decodable>(_ url: URL) -> T? {
  guard let data = try? Data(contentsOf: url) else { return nil }
  return try? JSONDecoder().decode(T.self, from: data)
}

final class Model: ObservableObject {
  @Published var now = Date()
  @Published var timers: [ActiveTimer]?        // nil: Timers Paralelos PRO is not running
  @Published var tablero: TableroSnapshot?     // nil: Tablero IA closed or silent for 30 s

  func refresh() {
    now = Date()
    if let s: TimersSnapshot = load(timersFile), alive(s.pid) { timers = s.timers } else { timers = nil }
    if let s: TableroSnapshot = load(tableroFile), alive(s.pid),
       now.timeIntervalSince1970 - s.at / 1000 < 30 { tablero = s } else { tablero = nil }
  }
}

// MARK: - View

extension Color {
  init(hex: String) {
    var v: UInt64 = 0x888888
    Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))).scanHexInt64(&v)
    self.init(red: Double((v >> 16) & 255) / 255, green: Double((v >> 8) & 255) / 255, blue: Double(v & 255) / 255)
  }
}
func countdown(_ s: Double) -> String {
  let t = Int(s.rounded(.up)), h = t / 3600, m = t % 3600 / 60, sec = t % 60
  return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%02d:%02d", m, sec)
}
func short(_ s: String, _ n: Int = 22) -> String { s.count > n ? String(s.prefix(n - 1)) + "…" : s }
func gigas(_ mb: Int) -> String {
  let f = NumberFormatter()
  f.locale = Locale(identifier: "es_ES"); f.minimumFractionDigits = 1; f.maximumFractionDigits = 1
  return (f.string(from: NSNumber(value: Double(mb) / 1024)) ?? "?") + " GB"
}
func open(_ app: URL) {
  let c = NSWorkspace.OpenConfiguration()
  c.activates = true
  NSWorkspace.shared.openApplication(at: app, configuration: c)
}

struct TimerChip: View {
  let t: ActiveTimer
  let now: Date
  var body: some View {
    HStack(spacing: 5) {
      Circle().fill(Color(hex: t.color)).frame(width: 8, height: 8)
      Text(short(t.label.isEmpty ? "Timer" : t.label))
      if t.state == "waiting" {
        Text("en cola").foregroundStyle(.secondary)
      } else {
        Text(countdown(t.remaining(now))).monospacedDigit()
          .foregroundStyle(t.state == "running" && t.remaining(now) < 60 ? Color.red : Color.primary)
        if t.state == "paused" { Image(systemName: "pause.fill").font(.system(size: 9)) }
      }
    }
    .opacity(t.state == "running" ? 1 : 0.55)
  }
}

struct Count: View {
  let n: Int
  let icon: String
  let tint: Color
  let help: String
  var body: some View {
    HStack(spacing: 3) {
      Image(systemName: icon).font(.system(size: 10)).foregroundStyle(tint)
      Text("\(n)").monospacedDigit()
    }
    .help(help)
  }
}

struct BarView: View {
  @ObservedObject var model: Model
  // On screens with a notch: the room left of it, and right of it up to the bar's end. Content is held
  // to those widths so nothing slides under the camera housing.
  let leftWidth: CGFloat?
  let rightWidth: CGFloat?
  static let maxTimers = 8

  // Running first, the one finishing soonest leading; then paused, then queued.
  var ordered: [ActiveTimer] {
    let rank = ["running": 0, "paused": 1, "waiting": 2]
    return (model.timers ?? []).sorted {
      (rank[$0.state] ?? 3, $0.remaining(model.now)) < (rank[$1.state] ?? 3, $1.remaining(model.now))
    }
  }

  var body: some View {
    HStack(spacing: 0) {
      timers.contentShape(Rectangle()).onTapGesture { open(timersApp) }
        .frame(width: leftWidth, alignment: .leading).clipped()
      Spacer(minLength: 16)
      // With the notification corner left free the right side can get tight: drop the date, then the clock.
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 16) {
          iaPart
          Text(model.now, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
        }
        HStack(spacing: 16) { iaPart; Text(model.now, format: .dateTime.hour().minute()) }
        iaPart
      }
      .frame(width: rightWidth, alignment: .trailing)
    }
    .font(.system(size: 13, weight: .medium))
    .lineLimit(1)
    .padding(.horizontal, 12)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .environment(\.locale, Locale(identifier: "es_ES"))
  }

  @ViewBuilder var timers: some View {
    if let list = model.timers {
      if list.isEmpty {
        Label("Sin timers", systemImage: "timer").foregroundStyle(.secondary)
      } else {
        HStack(spacing: 16) {
          ForEach(ordered.prefix(Self.maxTimers)) { TimerChip(t: $0, now: model.now) }
          if list.count > Self.maxTimers { Text("+\(list.count - Self.maxTimers)").foregroundStyle(.secondary) }
        }
      }
    } else {
      Label("Timers cerrado", systemImage: "timer").foregroundStyle(.tertiary)
    }
  }

  var iaPart: some View { tablero.contentShape(Rectangle()).onTapGesture { open(tableroApp) } }

  @ViewBuilder var tablero: some View {
    if let t = model.tablero {
      HStack(spacing: 10) {
        Text("IA").foregroundStyle(.secondary)
        if t.permission > 0 { Count(n: t.permission, icon: "exclamationmark.circle.fill", tint: .red, help: "Piden permiso") }
        Count(n: t.working, icon: "play.fill", tint: .green, help: "Trabajando")
        Count(n: t.waiting, icon: "pause.fill", tint: .orange, help: "Te esperan")
        HStack(spacing: 3) {
          Image(systemName: "memorychip").font(.system(size: 11)).foregroundStyle(.secondary)
          Text(gigas(t.memMB)).monospacedDigit()
        }
        .help("Memoria de Claude Code + Cursor")
      }
    } else {
      Text("Tablero IA cerrado").foregroundStyle(.tertiary)
    }
  }
}

// MARK: - Window

final class BarPanel: NSPanel {
  override var canBecomeKey: Bool { false }
  override var canBecomeMain: Bool { false }
  // AppKit pushes windows below the menu bar and the notch; this one belongs exactly up there.
  override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}
final class BarHost: NSHostingView<BarView> {
  override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
  override func menu(for event: NSEvent) -> NSMenu? { AppDelegate.shared.contextMenu() }
}

// The Window Server's own menu bar windows, in global coordinates (top-left origin).
func menuBars(_ option: CGWindowListOption) -> [CGRect] {
  let level = Int(CGWindowLevelForKey(.mainMenuWindow))
  let list = CGWindowListCopyWindowInfo(option, kCGNullWindowID) as? [[String: Any]] ?? []
  return list.compactMap { w in
    guard w[kCGWindowOwnerName as String] as? String == "Window Server",
          w[kCGWindowLayer as String] as? Int == level,
          (w[kCGWindowName as String] as? String).map({ $0 == "Menubar" }) ?? true,
          let b = w[kCGWindowBounds as String] as? NSDictionary,
          let r = CGRect(dictionaryRepresentation: b) else { return nil }
    return r
  }
}

struct Bar {
  let panel: BarPanel
  let display: CGRect   // screen in global coordinates
  let height: CGFloat
  var shown = false

  // Showing = any part of a menu bar on this screen has come down into view.
  func systemMenuBarShowing(_ onScreen: [CGRect]) -> Bool {
    onScreen.contains { $0.minX < display.maxX && $0.maxX > display.minX &&
      $0.minY > display.minY - height + 1 && $0.minY < display.maxY }
  }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
  static var shared: AppDelegate!
  let model = Model()
  var bars: [CGDirectDisplayID: Bar] = [:]
  // `defaults write net.horacio.barrasuperior anchoAvisos -int 420` to widen the free corner.
  var notificationCorner: CGFloat {
    let w = UserDefaults.standard.integer(forKey: "anchoAvisos")
    return CGFloat(w > 0 ? w : 380)
  }
  var leaveNotificationsFree: Bool {
    UserDefaults.standard.object(forKey: "dejarLibreAvisos") as? Bool ?? true
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    model.refresh()
    every(1) { [weak self] in self?.model.refresh() }
    every(0.08) { [weak self] in self?.syncVisibility() }
    NotificationCenter.default.addObserver(self, selector: #selector(rebuild),
                                           name: NSApplication.didChangeScreenParametersNotification, object: nil)
    rebuild()
    if !UserDefaults.standard.bool(forKey: "loginItemOffered") {
      UserDefaults.standard.set(true, forKey: "loginItemOffered")
      try? SMAppService.mainApp.register()
    }
  }

  // .common so the bar keeps counting while a menu is open.
  func every(_ seconds: TimeInterval, _ body: @escaping () -> Void) {
    RunLoop.main.add(Timer(timeInterval: seconds, repeats: true) { _ in body() }, forMode: .common)
  }

  @objc func rebuild() {
    for bar in bars.values { bar.panel.orderOut(nil) }
    bars = [:]
    let all = menuBars(.optionAll)
    for screen in NSScreen.screens {
      guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else { continue }
      let display = CGDisplayBounds(id)
      let height = all.first { abs($0.minX - display.minX) < 1 && abs($0.width - display.width) < 1 }?.height ?? 30
      // Notification banners drop in at the top right; the bar stops short of that corner so it
      // never paints over them. 380 pt = a banner (~345) plus its margin.
      let gap: CGFloat = leaveNotificationsFree ? notificationCorner : 0
      var leftWidth: CGFloat?, rightWidth: CGFloat?
      if screen.safeAreaInsets.top > 0, let l = screen.auxiliaryTopLeftArea, let r = screen.auxiliaryTopRightArea {
        leftWidth = l.width - 20
        rightWidth = max(0, r.width - gap - 20)
      }

      let f = screen.frame
      let panel = BarPanel(contentRect: NSRect(x: f.minX, y: f.maxY - height, width: f.width - gap, height: height),
                           styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
      // One level under the real menu bar: when it slides in it covers us even before we fade.
      panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) - 1)
      panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
      // Solid, not glass: windows reach the top edge when the menu bar hides, and their text
      // showing through a translucent strip made the bar unreadable.
      panel.isOpaque = true
      // A fixed grey per appearance: on macOS 26 windowBackgroundColor itself lets the text through.
      panel.backgroundColor = NSColor(name: nil) {
        $0.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(white: 0.14, alpha: 1) : NSColor(white: 0.93, alpha: 1)
      }
      panel.hasShadow = false
      panel.hidesOnDeactivate = false
      panel.isReleasedWhenClosed = false
      panel.alphaValue = 0

      panel.contentView = BarHost(rootView: BarView(model: model, leftWidth: leftWidth, rightWidth: rightWidth))

      bars[id] = Bar(panel: panel, display: display, height: height)
    }
    syncVisibility()
  }

  func syncVisibility() {
    let onScreen = menuBars(.optionOnScreenOnly)
    for (id, bar) in bars {
      let show = !bar.systemMenuBarShowing(onScreen)
      guard show != bar.shown else { continue }
      bars[id]?.shown = show
      let panel = bar.panel
      if show { panel.orderFrontRegardless() }
      NSAnimationContext.runAnimationGroup({ c in
        c.duration = show ? 0.18 : 0.08
        panel.animator().alphaValue = show ? 1 : 0
      }, completionHandler: { [weak self] in
        // Off screen for real once faded, so it never catches a click meant for what is beneath.
        if self?.bars[id]?.shown == false { panel.orderOut(nil) }
      })
    }
  }

  // MARK: Right-click menu

  func contextMenu() -> NSMenu {
    let menu = NSMenu()
    func item(_ title: String, _ action: Selector) -> NSMenuItem {
      let i = NSMenuItem(title: title, action: action, keyEquivalent: "")
      i.target = self
      menu.addItem(i)
      return i
    }
    _ = item("Abrir Timers Paralelos PRO", #selector(openTimers))
    _ = item("Abrir Tablero IA", #selector(openTablero))
    menu.addItem(.separator())
    item("Dejar libre la esquina de avisos", #selector(toggleNotificationCorner)).state = leaveNotificationsFree ? .on : .off
    item("Abrir al iniciar sesión", #selector(toggleLogin)).state = SMAppService.mainApp.status == .enabled ? .on : .off
    menu.addItem(.separator())
    _ = item("Salir de Barra Superior", #selector(quit))
    return menu
  }
  @objc func openTimers() { open(timersApp) }
  @objc func openTablero() { open(tableroApp) }
  @objc func toggleLogin() {
    if SMAppService.mainApp.status == .enabled { try? SMAppService.mainApp.unregister() }
    else { try? SMAppService.mainApp.register() }
  }
  @objc func toggleNotificationCorner() {
    UserDefaults.standard.set(!leaveNotificationsFree, forKey: "dejarLibreAvisos")
    rebuild()
  }
  @objc func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let delegate = AppDelegate()
AppDelegate.shared = delegate
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
