import SwiftUI

enum FocusPetTheme {
    enum Palette {
        static let mist = Color(red: 0.94, green: 0.96, blue: 0.95)
        static let cloud = Color(red: 0.98, green: 0.98, blue: 0.97)
        static let rain = Color(red: 0.88, green: 0.92, blue: 0.95)
        static let warm = Color(red: 0.95, green: 0.91, blue: 0.86)
        static let sage = Color(red: 0.83, green: 0.88, blue: 0.84)
        static let peach = Color(red: 0.95, green: 0.83, blue: 0.77)
        static let sand = Color(red: 0.90, green: 0.83, blue: 0.73)
        static let ink = Color(red: 0.28, green: 0.32, blue: 0.36)
        static let inkSoft = Color(red: 0.48, green: 0.54, blue: 0.58)
        static let panel = Color.white.opacity(0.80)
        static let panelStroke = Color.white.opacity(0.92)
        static let progressTrack = Color(red: 0.91, green: 0.93, blue: 0.92)
        static let progressFill = Color(red: 0.77, green: 0.84, blue: 0.79)
    }

    enum Spacing {
        static let xSmall: CGFloat = 6
        static let small: CGFloat = 10
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 28
        static let xxLarge: CGFloat = 36
    }

    enum Radius {
        static let small: CGFloat = 18
        static let medium: CGFloat = 24
        static let large: CGFloat = 32
        static let xLarge: CGFloat = 40
    }

    enum Shadow {
        static let panel = Color.black.opacity(0.05)
    }

    enum Typography {
        static func hero(compact: Bool = false) -> Font {
            .system(size: compact ? 28 : 32, weight: .semibold, design: .rounded)
        }

        static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let headline = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .rounded)
        static let subheadline = Font.system(.subheadline, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
        static let timer = Font.system(size: 48, weight: .bold, design: .rounded)
    }
}
