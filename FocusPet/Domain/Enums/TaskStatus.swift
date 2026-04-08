import Foundation

enum TaskStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case active
    case paused
    case overdue
    case completed
    case deleted

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .active:
            "进行中"
        case .paused:
            "已暂停"
        case .overdue:
            "已逾期"
        case .completed:
            "已完成"
        case .deleted:
            "已删除"
        }
    }
}
