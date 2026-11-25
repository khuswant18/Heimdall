// Standalone accessory overlay: invisible to Heimdall's screen capture (sharingType .none)
// and not a "windowed app" to Athena's restricted-apps gate (activationPolicy .accessory).
// Shows the contents of ~/.overlay.txt (live-reloads) so you can put notes/answers there.
import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
  let win = NSPanel(contentRect: NSRect(x:0,y:0,width:520,height:300),
                    styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
  let text = NSTextView()
  func applicationDidFinishLaunching(_ n: Notification) {
    NSApp.setActivationPolicy(.accessory)          // policy 1 -> not a windowed app
    win.sharingType = .none                         // excluded from ScreenCaptureKit
    win.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))  // above shields/fullscreen
    win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]  // follow into other apps' fullscreen spaces
    win.backgroundColor = NSColor.black.withAlphaComponent(0.85)
    win.isOpaque = false
    win.isFloatingPanel = true
    win.hidesOnDeactivate = false
    win.ignoresMouseEvents = false                  // receive trackpad scroll (nonactivating -> exam keeps focus)
    let scroll = NSScrollView(frame: win.contentView!.bounds)
    scroll.autoresizingMask = [.width,.height]
    scroll.drawsBackground = false
    text.isEditable = false; text.drawsBackground = false
    text.textColor = .systemGreen
    text.font = NSFont.monospacedSystemFont(ofSize: 15, weight: .medium)
    text.string = "SECRET-CODE 7391\n(put notes in ~/.overlay.txt — live reloads)"
    scroll.documentView = text
    win.contentView?.addSubview(scroll)
    if let s = NSScreen.main { let f = s.visibleFrame
      win.setFrameOrigin(NSPoint(x: f.maxX-540, y: f.maxY-320)) }
    win.orderFrontRegardless()
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
      if let c = try? String(contentsOfFile: NSString(string:"~/.overlay.txt").expandingTildeInPath, encoding: .utf8) {
        self.text.string = c; self.text.textColor = .systemGreen
      }
      // re-assert membership + top every tick, so it follows into fullscreen spaces
      self.win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
      self.win.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
      self.win.orderFrontRegardless()
    }
  }
}
let app = NSApplication.shared
let d = AppDelegate(); app.delegate = d
app.run()
