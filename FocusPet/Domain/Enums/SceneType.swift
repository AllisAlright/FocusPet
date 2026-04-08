import Foundation

enum SceneType: String, Codable, CaseIterable, Identifiable, Sendable {
    case rainyWindow
    case duskPark
    case morningCafe

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rainyWindow:
            "雨天窗边"
        case .duskPark:
            "黄昏长椅"
        case .morningCafe:
            "晨光咖啡馆"
        }
    }
}
