import SwiftUI

enum Palette {
    static func paper(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.10, green: 0.08, blue: 0.14) : Color(red: 0.98, green: 0.96, blue: 0.92)
    }
    static func ink(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.96, green: 0.93, blue: 0.99) : Color(red: 0.22, green: 0.13, blue: 0.30)
    }
    static func accent(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.76, green: 0.65, blue: 0.99) : Color(red: 0.40, green: 0.24, blue: 0.62)
    }
    static let keyColors: [Color] = [
        Color(red: 0.84, green: 0.74, blue: 0.99), Color(red: 0.98, green: 0.74, blue: 0.65),
        Color(red: 0.81, green: 0.86, blue: 0.56), Color(red: 0.99, green: 0.85, blue: 0.56),
        Color(red: 0.67, green: 0.83, blue: 0.85), Color(red: 0.91, green: 0.73, blue: 0.84)
    ]
}
