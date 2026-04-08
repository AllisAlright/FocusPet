import Foundation

enum PetType: String, Codable, CaseIterable, Identifiable, Sendable {
    case rabbit
    case cat
    case dog
    case hamster

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rabbit:
            "兔兔"
        case .cat:
            "猫猫"
        case .dog:
            "小狗"
        case .hamster:
            "仓仓"
        }
    }
}
