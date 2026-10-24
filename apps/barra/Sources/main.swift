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
import AVFoundation
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

// "Memory Used" as Activity Monitor computes it: app memory (anonymous pages not marked
// purgeable) + wired + compressed. Physical is the installed RAM.
func systemMemory() -> (used: Double, total: Double)? {
  var stats = vm_statistics64()
  var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
  let ok = withUnsafeMutablePointer(to: &stats) {
    $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count) }
  }
  guard ok == KERN_SUCCESS else { return nil }
  let pages = Double(stats.internal_page_count) - Double(stats.purgeable_count)
    + Double(stats.wire_count) + Double(stats.compressor_page_count)
  return (pages * Double(vm_kernel_page_size), Double(ProcessInfo.processInfo.physicalMemory))
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
  @Published var memory: (used: Double, total: Double)?
  @Published var snap = SnapState.idle
  private let snapper = Snapper()

  enum SnapState { case idle, busy, ok, failed }

  func takePhoto() {
    guard snap != .busy else { return }
    snap = .busy
    snapper.snap { [weak self] url in
      self?.snap = url == nil ? .failed : .ok
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { self?.snap = .idle }
    }
  }

  func refresh() {
    now = Date()
    memory = systemMemory()
    if let s: TimersSnapshot = load(timersFile), alive(s.pid) { timers = s.timers } else { timers = nil }
    if let s: TableroSnapshot = load(tableroFile), alive(s.pid),
       now.timeIntervalSince1970 - s.at / 1000 < 30 { tablero = s } else { tablero = nil }
  }
}

// MARK: - Webcam

// One quiet photo per click: no window, no preview, straight to ~/Pictures/Barra Superior/. The
// camera's green light still comes on for the second it is open; macOS does that in hardware.
final class Snapper: NSObject, AVCapturePhotoCaptureDelegate {
  static let folder = home.appendingPathComponent("Pictures/Barra Superior")
  private var session: AVCaptureSession?
  private var done: ((URL?) -> Void)?

  func snap(_ done: @escaping (URL?) -> Void) {
    guard session == nil else { return }
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized: start(done)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { ok in DispatchQueue.main.async { ok ? self.start(done) : done(nil) } }
    default: done(nil)
    }
  }

  // The Mac's own camera, not Camo / OBS / Elgato virtual ones; any camera if there is no built-in
  // one (lid closed on an external display).
  private func camera() -> AVCaptureDevice? {
    AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
      .devices.first ?? AVCaptureDevice.default(for: .video)
  }

  private func start(_ done: @escaping (URL?) -> Void) {
    let output = AVCapturePhotoOutput()   // an output belongs to one session, so a fresh one each time
    guard let cam = camera(), let input = try? AVCaptureDeviceInput(device: cam) else { done(nil); return }
    let s = AVCaptureSession()
    s.sessionPreset = .photo
    guard s.canAddInput(input), s.canAddOutput(output) else { done(nil); return }
    s.addInput(input)
    s.addOutput(output)
    session = s
    self.done = done
    DispatchQueue.global(qos: .userInitiated).async {
      s.startRunning()
      // The first frames come out dark while auto-exposure settles.
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
        let settings = output.availablePhotoCodecTypes.contains(.jpeg)
          ? AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg]) : AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
      }
    }
  }

  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    var saved: URL?
    if error == nil, let data = photo.fileDataRepresentation() {
      try? FileManager.default.createDirectory(at: Self.folder, withIntermediateDirectories: true)
      let f = DateFormatter()
      f.dateFormat = "yyyy-MM-dd HH.mm.ss"
      let url = Self.folder.appendingPathComponent(f.string(from: Date()) + ".jpg")
      if (try? data.write(to: url)) != nil { saved = url }
    }
    let s = session
    DispatchQueue.global().async { s?.stopRunning() }
    DispatchQueue.main.async {
      self.session = nil
      self.done?(saved)
      self.done = nil
    }
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
func gigas(_ mb: Int) -> String {
  let f = NumberFormatter()
  f.locale = Locale(identifier: "es_ES"); f.minimumFractionDigits = 1; f.maximumFractionDigits = 1
  return (f.string(from: NSNumber(value: Double(mb) / 1024)) ?? "?") + " GB"
}
func gigasBytes(_ bytes: Double, digits: Int) -> String {
  let f = NumberFormatter()
  f.locale = Locale(identifier: "es_ES"); f.minimumFractionDigits = digits; f.maximumFractionDigits = digits
  return f.string(from: NSNumber(value: bytes / 1_073_741_824)) ?? "?"
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
      Text(t.label.isEmpty ? "Timer" : t.label)  // whole name; only cut if the bar runs out of room
      if t.state == "waiting" {
        Text("en cola").foregroundStyle(.secondary)
      } else {
        Text(countdown(t.remaining(now))).monospacedDigit()
          .foregroundStyle(t.state == "running" && t.remaining(now) < 60 ? Color.red : Color.primary)
        if t.state == "paused" { Image(systemName: "pause.fill").font(.system(size: 9)) }
      }
    }
    .opacity(t.state == "running" ? 1 : 0.75)
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

// The pipe between blocks.
struct Sep: View {
  var body: some View { Text("|").foregroundStyle(.white.opacity(0.55)) }
}

struct BarView: View {
  @ObservedObject var model: Model
  // On screens with a notch: the room left of it, and right of it up to the bar's end. Content is held
  // to those widths so nothing slides under the camera housing.
  let leftWidth: CGFloat?
  let rightWidth: CGFloat?
  static let maxTimers = 8
  // macOS draws its camera/microphone dot (the orange one) in the top-right corner, over everything;
  // the bar's content ends before it.
  static let trailingRoom: CGFloat = 40

  // Only the timers that are counting down, the one finishing soonest first. Paused and queued
  // ones stay in Timers Paralelos PRO.
  var running: [ActiveTimer] {
    (model.timers ?? []).filter { $0.state == "running" }.sorted { $0.remaining(model.now) < $1.remaining(model.now) }
  }

  var body: some View {
    HStack(spacing: 0) {
      HStack(spacing: 10) {
        camera
        Sep()
        timers.contentShape(Rectangle()).onTapGesture { open(timersApp) }
      }
      .frame(width: leftWidth, alignment: .leading).clipped()
      Spacer(minLength: 16)
      // Order on the right, blocks split by a pipe: Tablero IA (its memory last) | the Mac's RAM | the
      // clock. When it gets tight (a notched screen with the notification corner left free): drop the
      // date, then the "IA" label and a decimal, then the GB units, then the clock.
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 10) {
          iaPart(label: true, unit: true); Sep(); macMemory(compact: false); Sep()
          Text(model.now, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
        }
        HStack(spacing: 10) {
          iaPart(label: true, unit: true); Sep(); macMemory(compact: false); Sep(); Text(model.now, format: .dateTime.hour().minute())
        }
        HStack(spacing: 8) {
          iaPart(label: false, unit: true); Sep(); macMemory(compact: true); Sep(); Text(model.now, format: .dateTime.hour().minute())
        }
        HStack(spacing: 8) {
          iaPart(label: false, unit: false); Sep(); macMemory(compact: true); Sep(); Text(model.now, format: .dateTime.hour().minute())
        }
        HStack(spacing: 8) { iaPart(label: false, unit: false); Sep(); macMemory(compact: true) }
      }
      .frame(width: rightWidth, alignment: .trailing)
    }
    .font(.system(size: 13, weight: .medium))
    .lineLimit(1)
    .padding(.leading, 12)
    .padding(.trailing, BarView.trailingRoom)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .environment(\.locale, Locale(identifier: "es_ES"))
  }

  // Click: one webcam photo, saved quietly. The icon answers for a moment: ✓ saved, ✕ failed.
  var camera: some View {
    let icon = switch model.snap {
      case .idle: "camera"
      case .busy: "camera.fill"
      case .ok: "checkmark"
      case .failed: "xmark"
    }
    return Image(systemName: icon)
      .font(.system(size: 13, weight: .semibold))
      .frame(width: 18)
      .opacity(model.snap == .busy ? 0.6 : 1)
      .contentShape(Rectangle())
      .onTapGesture { model.takePhoto() }
      .help("Foto con la webcam → Imágenes/Barra Superior")
  }

  @ViewBuilder var timers: some View {
    if model.timers != nil {
      let list = running
      if list.isEmpty {
        Label("Ningún timer en marcha", systemImage: "timer").foregroundStyle(.secondary)
      } else {
        HStack(spacing: 10) {
          ForEach(Array(list.prefix(Self.maxTimers).enumerated()), id: \.element.id) { i, t in
            if i > 0 { Sep() }
            TimerChip(t: t, now: model.now)
          }
          if list.count > Self.maxTimers { Text("+\(list.count - Self.maxTimers)").foregroundStyle(.secondary) }
        }
      }
    } else {
      Label("Timers cerrado", systemImage: "timer").foregroundStyle(.tertiary)
    }
  }

  // The Mac as a whole, as Activity Monitor shows it: memory used / physical memory.
  @ViewBuilder func macMemory(compact: Bool) -> some View {
    if let m = model.memory {
      Text(compact ? "\(gigasBytes(m.used, digits: 1))/\(gigasBytes(m.total, digits: 0))"
                   : "\(gigasBytes(m.used, digits: 2)) / \(gigasBytes(m.total, digits: 0)) GB").monospacedDigit()
      .help("Memoria usada / memoria física del Mac (como el Monitor de Actividad)")
    }
  }

  func iaPart(label: Bool, unit: Bool) -> some View {
    tablero(label: label, unit: unit).contentShape(Rectangle()).onTapGesture { open(tableroApp) }
  }

  @ViewBuilder func tablero(label: Bool, unit: Bool) -> some View {
    if let t = model.tablero {
      HStack(spacing: 10) {
        if label { Text("IA").foregroundStyle(.secondary) }
        if t.permission > 0 { Count(n: t.permission, icon: "exclamationmark.circle.fill", tint: .red, help: "Piden permiso") }
        Count(n: t.working, icon: "play.fill", tint: .green, help: "Trabajando")
        Count(n: t.waiting, icon: "pause.fill", tint: .orange, help: "Te esperan")
        HStack(spacing: 3) {
          Image(systemName: "memorychip").font(.system(size: 11)).foregroundStyle(.secondary)
          Text(unit ? gigas(t.memMB) : String(gigas(t.memMB).dropLast(3))).monospacedDigit()
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
// Rounded like a Mac window, in the sky blue of Horacio's wallpaper (#4CB2E2) so it never passes
// for an app. Drawn on a layer because the corners need the window itself to be clear. The panel
// is forced to dark appearance, so text and symbols come out white on the blue in either mode.
final class BarBackground: NSView {
  static let radius: CGFloat = 12
  static let color = NSColor(srgbRed: 0x4C / 255, green: 0xB2 / 255, blue: 0xE2 / 255, alpha: 1)
  override var wantsUpdateLayer: Bool { true }
  override func updateLayer() {
    guard let layer else { return }
    layer.backgroundColor = Self.color.cgColor
    layer.borderColor = NSColor(white: 1, alpha: 0.18).cgColor
    layer.borderWidth = 0.5
    layer.cornerRadius = Self.radius
    layer.cornerCurve = .continuous
    layer.masksToBounds = true
  }
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
    return CGFloat(w > 0 ? w : 370)
  }
  var leaveNotificationsFree: Bool {
    UserDefaults.standard.object(forKey: "dejarLibreAvisos") as? Bool ?? false
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
      // Optional (off by default, since the bar now sits under the banners): stop short of the
      // top-right corner where they drop in. 370 pt = a banner (344) plus its 15 pt margin.
      let gap: CGFloat = leaveNotificationsFree ? notificationCorner : 0
      var leftWidth: CGFloat?, rightWidth: CGFloat?
      if screen.safeAreaInsets.top > 0, let l = screen.auxiliaryTopLeftArea, let r = screen.auxiliaryTopRightArea {
        leftWidth = l.width - 20
        rightWidth = max(0, r.width - gap - BarView.trailingRoom - 8)
      }

      let f = screen.frame
      let panel = BarPanel(contentRect: NSRect(x: f.minX, y: f.maxY - height, width: f.width - gap, height: height),
                           styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
      // Dock level (20): above every app window (0) and floating panel (3), but under Notification
      // Centre (21), whose banners land on top of the bar, and under the real menu bar (24), which
      // covers us as it slides in even before we fade.
      panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.dockWindow)))
      panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
      // Clear window, solid rounded background (BarBackground). Solid, not glass: windows reach the
      // top edge when the menu bar hides, and their text showing through made the bar unreadable.
      panel.isOpaque = false
      panel.backgroundColor = .clear
      panel.appearance = NSAppearance(named: .darkAqua)
      panel.hasShadow = false
      panel.hidesOnDeactivate = false
      panel.isReleasedWhenClosed = false
      panel.alphaValue = 0

      let background = BarBackground()
      background.wantsLayer = true
      let host = BarHost(rootView: BarView(model: model, leftWidth: leftWidth, rightWidth: rightWidth))
      host.autoresizingMask = [.width, .height]
      background.addSubview(host)
      panel.contentView = background
      host.frame = background.bounds

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
    _ = item("Abrir carpeta de fotos", #selector(openPhotos))
    menu.addItem(.separator())
    item("Dejar libre la esquina de avisos", #selector(toggleNotificationCorner)).state = leaveNotificationsFree ? .on : .off
    item("Abrir al iniciar sesión", #selector(toggleLogin)).state = SMAppService.mainApp.status == .enabled ? .on : .off
    menu.addItem(.separator())
    _ = item("Salir de Barra Superior", #selector(quit))
    return menu
  }
  @objc func openTimers() { open(timersApp) }
  @objc func openTablero() { open(tableroApp) }
  @objc func openPhotos() {
    try? FileManager.default.createDirectory(at: Snapper.folder, withIntermediateDirectories: true)
    NSWorkspace.shared.open(Snapper.folder)
  }
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
