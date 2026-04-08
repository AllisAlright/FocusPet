import Foundation

enum TimerMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case countUp
    case countDown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .countUp:
            "正计时"
        case .countDown:
            "倒计时"
        }
    }
}
