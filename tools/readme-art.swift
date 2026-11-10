import AppKit
import ImageIO
import UniformTypeIdentifiers

// Recreate the app's original key characters for README artwork. No external assets.
let root = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".github/assets")
try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
let width = 960, height = 400
let colors: [NSColor] = [
    NSColor(srgbRed: 0.84, green: 0.74, blue: 0.99, alpha: 1),
    NSColor(srgbRed: 0.98, green: 0.74, blue: 0.65, alpha: 1),
    NSColor(srgbRed: 0.81, green: 0.86, blue: 0.56, alpha: 1),
    NSColor(srgbRed: 0.99, green: 0.85, blue: 0.56, alpha: 1),
    NSColor(srgbRed: 0.67, green: 0.83, blue: 0.85, alpha: 1),
    NSColor(srgbRed: 0.91, green: 0.73, blue: 0.84, alpha: 1)
]
let face = NSColor(srgbRed: 0.25, green: 0.16, blue: 0.32, alpha: 1)
func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
    NSRect(x: x, y: CGFloat(height) - y - h, width: w, height: h)
}
func rounded(_ rectangle: NSRect, _ radius: CGFloat, _ color: NSColor) {
    color.setFill(); NSBezierPath(roundedRect: rectangle, xRadius: radius, yRadius: radius).fill()
}
func text(_ string: String, top: CGFloat, size: CGFloat, weight: NSFont.Weight, color: NSColor) {
    let descriptor = NSFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.rounded)!
    let font = NSFont(descriptor: descriptor, size: size)!
    let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
    (string as NSString).draw(in: rect(20, top, 920, size * 1.4), withAttributes: [
        .font: font, .foregroundColor: color, .paragraphStyle: paragraph])
}
func frame(dark: Bool, time: Double, happy: Bool) -> NSBitmapImageRep {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: width * 4, bitsPerPixel: 32)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill(using: .copy)
    let paper = dark ? NSColor(srgbRed: 0.10, green: 0.08, blue: 0.14, alpha: 1)
                     : NSColor(srgbRed: 0.98, green: 0.96, blue: 0.92, alpha: 1)
    let ink = dark ? NSColor(srgbRed: 0.96, green: 0.93, blue: 0.99, alpha: 1)
                   : NSColor(srgbRed: 0.22, green: 0.13, blue: 0.30, alpha: 1)
    rounded(rect(0, 0, 960, 400), 28, paper)
    text("Virtual Keys Please", top: 28, size: 52, weight: .bold, color: ink)
    text("A little courtesy. A lot of keys.", top: 96, size: 19, weight: .medium,
         color: ink.withAlphaComponent(0.65))
    let halo = NSBezierPath(ovalIn: rect(296, 166, 368, 204))
    ink.withAlphaComponent(dark ? 0.055 : 0.035).setFill(); halo.fill()
    if happy {
        for i in 0..<28 {
            let angle = Double(i) * 2.39996
            let distance = 96 + min(time, 1.8) * (34 + Double(i % 4) * 7)
            let x = 480 + cos(angle) * distance
            let y = 266 + sin(angle) * distance * 0.68 + time * time * 3
            rounded(rect(x, y, i % 2 == 0 ? 5 : 9, 4), 2,
                    colors[i % 6].withAlphaComponent(max(0.12, 0.85 - time * 0.24)))
        }
    }
    for i in 0..<6 {
        let wave = sin(time * (happy ? 5 : 2.3) + Double(i) * 0.8)
        let x = 480 + Double(i % 3 - 1) * 104 - 44
        let y = 170 + Double(i / 3) * 104 - (happy ? abs(wave) * 9 : wave * 4)
        let box = rect(x, y, 88, 84)
        rounded(box.offsetBy(dx: 0, dy: -7), 20, ink.withAlphaComponent(0.16))
        rounded(box, 20, colors[i])
        NSColor.white.withAlphaComponent(0.45).setStroke()
        let inset = NSBezierPath(roundedRect: box.insetBy(dx: 5, dy: 5), xRadius: 15, yRadius: 15)
        inset.lineWidth = 1.5; inset.stroke()
        for side in [-1.0, 1.0] {
            let eyeX = x + 44 + side * 10
            if happy {
                let eye = NSBezierPath()
                eye.move(to: NSPoint(x: eyeX - 3.5, y: CGFloat(height) - y - 36))
                eye.curve(to: NSPoint(x: eyeX + 3.5, y: CGFloat(height) - y - 36),
                          controlPoint1: NSPoint(x: eyeX - 1, y: CGFloat(height) - y - 30),
                          controlPoint2: NSPoint(x: eyeX + 1, y: CGFloat(height) - y - 30))
                face.setStroke(); eye.lineWidth = 2.5; eye.lineCapStyle = .round; eye.stroke()
            } else {
                face.setFill(); NSBezierPath(ovalIn: rect(eyeX - 2.5, y + 32, 5, 7)).fill()
            }
        }
        let mouth = NSBezierPath()
        mouth.move(to: NSPoint(x: x + 37, y: CGFloat(height) - y - 52))
        mouth.curve(to: NSPoint(x: x + 51, y: CGFloat(height) - y - 52),
                    controlPoint1: NSPoint(x: x + 41, y: CGFloat(height) - y - 60),
                    controlPoint2: NSPoint(x: x + 47, y: CGFloat(height) - y - 60))
        face.setStroke(); mouth.lineWidth = 2.5; mouth.lineCapStyle = .round; mouth.stroke()
    }
    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}
for (mode, dark) in [("light", false), ("dark", true)] {
    let still = frame(dark: dark, time: 1.1, happy: false)
    try still.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("hero-\(mode).png"))
    let url = root.appendingPathComponent("hero-\(mode).gif")
    let count = 48
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, count, nil)!
    CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
    for i in 0..<count {
        let time = Double(i) / 12
        let image = frame(dark: dark, time: time < 2 ? time : time - 2, happy: time >= 2)
        CGImageDestinationAddImage(destination, image.cgImage!,
            [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1.0 / 12]] as CFDictionary)
    }
    guard CGImageDestinationFinalize(destination) else { fatalError("GIF export failed") }
    print("Wrote \(mode) banner and animation")
}
