import Cocoa
let mode = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "none"
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let w = NSWindow(contentRect: NSRect(x:0,y:0,width:520,height:140),
                 styleMask: [.borderless], backing: .buffered, defer: false)
w.sharingType = (mode == "visible") ? .readOnly : .none   // control vs exclusion
w.level = .floating; w.backgroundColor = .black; w.isOpaque = true
let label = NSTextField(labelWithString: "SECRET-CODE 7391  [\(mode)]")
label.font = NSFont.boldSystemFont(ofSize: 34); label.textColor = .systemGreen
label.frame = NSRect(x:16,y:50,width:500,height:50)
w.contentView?.addSubview(label)
if let s = NSScreen.main { let f = s.visibleFrame; w.setFrameOrigin(NSPoint(x: f.maxX-540, y: f.maxY-160)) }
w.makeKeyAndOrderFront(nil); app.activate(ignoringOtherApps: true)
// also confirm the window is actually on-screen via the window server
DispatchQueue.main.asyncAfter(deadline: .now()+0.6){
  let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String:Any]] ?? []
  let mine = list.filter { ($0[kCGWindowOwnerPID as String] as? Int) == Int(ProcessInfo.processInfo.processIdentifier) }
  FileHandle.standardError.write("onscreen windows for me: \(mine.count), mode=\(mode)\n".data(using:.utf8)!)
}
app.run()
