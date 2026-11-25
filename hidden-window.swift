// Verifies ScreenCaptureKit window-exclusion (what Heimdall's capture relies on).
// A window set to .sharingType = .none is visible to your eyes but omitted from
// any ScreenCaptureKit capture — i.e. from Heimdall's screen snapshots.
// Build & run:  swiftc hidden-window.swift -o hw && ./hw
import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.accessory)                 // no Dock icon

let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 120),
                 styleMask: [.borderless], backing: .buffered, defer: false)
w.sharingType = .none                               // <-- excluded from screen capture
w.level = .floating                                 // always on top
w.backgroundColor = NSColor.black
w.isOpaque = true
w.hasShadow = true

let label = NSTextField(labelWithString:
  "SECRET-CODE 7391\nIf this text shows up in a capture,\nexclusion FAILED (capture CAN see it).")
label.font = NSFont.boldSystemFont(ofSize: 20)
label.textColor = .systemGreen
label.frame = NSRect(x: 16, y: 10, width: 388, height: 100)
label.maximumNumberOfLines = 3
w.contentView?.addSubview(label)

// top-right of the main screen
if let scr = NSScreen.main {
  let f = scr.visibleFrame
  w.setFrameOrigin(NSPoint(x: f.maxX - 440, y: f.maxY - 140))
}
w.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)
print("Hidden window is up (SECRET-CODE 7391). Capture the screen, then check if the code appears.")
print("Ctrl+C here to close it.")
app.run()
