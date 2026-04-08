import Foundation

struct SplitTaskSuggestion: Identifiable, Equatable {
    let id: UUID
    let title: String
    var isSelected: Bool

    init(id: UUID = UUID(), title: String, isSelected: Bool = true) {
        self.id = id
        self.title = title
        self.isSelected = isSelected
    }
}

enum SplitTaskError: LocalizedError, Equatable {
    case generationFailed

    var errorDescription: String? {
        switch self {
        case .generationFailed:
            return "这次整理没有成功，再试一次就好。"
        }
    }
}
