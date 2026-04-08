import Foundation

struct MemoItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    // Raw memo text captured quickly from the user.
    var content: String
    let createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isPinned: Bool = false,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.deletedAt = deletedAt
    }
}

extension MemoItem {
    var isDeleted: Bool {
        deletedAt != nil
    }

    var trimmedContent: String {
        content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var previewText: String {
        if trimmedContent.count <= 48 {
            return trimmedContent
        }
        return String(trimmedContent.prefix(48)) + "..."
    }

    var updatedAtText: String {
        DateDisplayFormatter.memoTimestamp(from: updatedAt)
    }

    var editorUpdatedAtText: String {
        DateDisplayFormatter.memoEditorUpdatedText(from: updatedAt)
    }

    var deletedAtText: String {
        guard let deletedAt else { return "" }
        return DateDisplayFormatter.deletedMemoText(from: deletedAt)
    }

    func updating(content: String, isPinned: Bool, referenceDate: Date = .now) -> MemoItem {
        var updated = self
        updated.content = content
        updated.isPinned = isPinned
        updated.updatedAt = referenceDate
        return updated
    }

    func softDeleting(referenceDate: Date = .now) -> MemoItem {
        var updated = self
        updated.deletedAt = referenceDate
        updated.updatedAt = referenceDate
        return updated
    }

    func restoring(referenceDate: Date = .now) -> MemoItem {
        var updated = self
        updated.deletedAt = nil
        updated.updatedAt = referenceDate
        return updated
    }
}
