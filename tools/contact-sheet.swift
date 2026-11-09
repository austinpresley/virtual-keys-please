import AppKit
let args = CommandLine.arguments
guard args.count == 3 else { fatalError("Usage: contact-sheet.swift shots-directory mode") }
let root = URL(fileURLWithPath: args[1])
let mode = args[2]
let states = ["ready", "working", "success", "already", "missing", "unsupported", "reset", "restored"]
let tile = CGSize(width: 560, height: 624)
let image = NSImage(size: CGSize(width: tile.width * 4, height: tile.height * 2))
image.lockFocus()
NSColor.windowBackgroundColor.setFill()
NSRect(origin: .zero, size: image.size).fill()
for (index, state) in states.enumerated() {
    guard let source = NSImage(contentsOf: root.appendingPathComponent("\(state)-\(mode).png")) else { fatalError(state) }
    let x = CGFloat(index % 4) * tile.width
    let y = CGFloat(1 - index / 4) * tile.height
    source.draw(in: NSRect(x: x, y: y, width: 560, height: 600))
    (state as NSString).draw(at: NSPoint(x: x + 20, y: y + 604), withAttributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .semibold), .foregroundColor: NSColor.labelColor])
}
image.unlockFocus()
guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
      let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("render") }
let out = root.appendingPathComponent("contact-\(mode).png")
try data.write(to: out)
print(out.path)
