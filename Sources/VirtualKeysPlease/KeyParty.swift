import SwiftUI

/// Original key characters are the decorative part of an otherwise native utility.
struct KeyParty: View {
    let visit: Visit
    let isTargeted: Bool
    let event: UUID
    let snapshot: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var began = Date()
    @State private var animating = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30,
                                paused: reduceMotion || snapshot || !animating)) { timeline in
            let time = snapshot ? 1.1 : reduceMotion ? 0 : timeline.date.timeIntervalSince(began)
            Canvas { context, size in draw(in: &context, size: size, time: max(0, time)) }
        }
        .accessibilityHidden(true)
        .task(id: "\(visit.rawValue)-\(event)") {
            began = Date()
            animating = true
            do { try await Task.sleep(for: .seconds(4)) }
            catch { return }
            if visit != .working { animating = false }
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, time: Double) {
        let joyful = [.success, .already].contains(visit)
        let working = visit == .working
        let worried = [.unsupported, .reset].contains(visit)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let halo = CGRect(x: center.x - 152, y: center.y - 76, width: 304, height: 152)
        context.fill(Path(ellipseIn: halo), with: .color(Palette.accent(scheme).opacity(isTargeted ? 0.12 : 0.05)))

        if joyful && !reduceMotion && time < 3.2 {
            for i in 0..<28 {
                let angle = Double(i) * 2.39996
                let distance = (24 + time * 64) * (0.72 + Double(i % 4) * 0.12)
                let x = center.x + cos(angle) * distance
                let y = center.y + sin(angle) * distance * 0.7 + time * time * 8 - 16
                let rect = CGRect(x: x, y: y, width: i % 2 == 0 ? 4 : 8, height: 4)
                context.fill(Path(roundedRect: rect, cornerRadius: 2),
                             with: .color(Palette.keyColors[i % 6].opacity(max(0, 1 - time / 3.2))))
            }
        }
        for i in 0..<6 {
            let column = i % 3
            let row = i / 3
            let wave = sin(time * (working ? 7 : 2.3) + Double(i) * 0.8)
            let entrance = reduceMotion ? 0 : max(0, 1 - time * 1.4) * Double(6 - i) * 10
            let bounce = reduceMotion ? 0 : (joyful ? abs(wave) * 12 * max(0, 1 - time / 4) : wave * 4)
            let x = center.x + Double(column - 1) * 84 - 36
            let y = center.y + Double(row) * 84 - 80 - bounce - entrance
            let rect = CGRect(x: x, y: y, width: 72, height: 68)
            var keyContext = context
            if worried { keyContext.opacity = 0.72 }
            keyContext.fill(Path(roundedRect: rect.offsetBy(dx: 0, dy: 6), cornerRadius: 16),
                            with: .color(Palette.ink(scheme).opacity(scheme == .dark ? 0.7 : 0.15)))
            keyContext.fill(Path(roundedRect: rect, cornerRadius: 16), with: .color(Palette.keyColors[i]))
            keyContext.stroke(Path(roundedRect: rect.insetBy(dx: 4, dy: 4), cornerRadius: 12),
                              with: .color(.white.opacity(0.4)), lineWidth: 1)
            let face = Color(red: 0.25, green: 0.16, blue: 0.32)
            let eyeY = rect.midY - 4
            for side in [-1.0, 1.0] {
                let eyeX = rect.midX + side * 8 + (isTargeted ? 2 : 0)
                if joyful {
                    var eye = Path()
                    eye.move(to: CGPoint(x: eyeX - 3, y: eyeY))
                    eye.addQuadCurve(to: CGPoint(x: eyeX + 3, y: eyeY), control: CGPoint(x: eyeX, y: eyeY - 5))
                    keyContext.stroke(eye, with: .color(face), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                } else {
                    keyContext.fill(Path(ellipseIn: CGRect(x: eyeX - 2, y: eyeY - 3, width: 4, height: worried ? 4 : 6)),
                                    with: .color(face))
                }
            }
            var mouth = Path()
            mouth.move(to: CGPoint(x: rect.midX - 5, y: rect.midY + 8))
            mouth.addQuadCurve(to: CGPoint(x: rect.midX + 5, y: rect.midY + 8),
                               control: CGPoint(x: rect.midX, y: rect.midY + (worried ? 3 : 15)))
            keyContext.stroke(mouth, with: .color(face), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }
}
