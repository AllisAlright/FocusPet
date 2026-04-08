import Foundation

enum FocusSessionStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case running
    case paused
    case finished
    case cancelled

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .running:
            "进行中"
        case .paused:
            "已暂停"
        case .finished:
            "已结束"
        case .cancelled:
            "已取消"
        }
    }
}
