import Foundation

struct TaskItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var title: String
    var notes: String
    let createdAt: Date
    var updatedAt: Date
    var dueDate: Date?
    // Total effort estimate used for automatic progress calculation.
    var estimatedMinutes: Int?
    // Time invested across all focus sessions.
    var spentMinutes: Int
    // Optional manual override that takes precedence over automatic progress.
    var manualProgress: Double?
    var status: TaskStatus
    var statusBeforeDeletion: TaskStatus?
    var enableFocus: Bool
    var preferredPet: PetType?
    var sourceMemoID: UUID?
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        dueDate: Date? = nil,
        estimatedMinutes: Int? = nil,
        spentMinutes: Int = 0,
        manualProgress: Double? = nil,
        status: TaskStatus = .active,
        statusBeforeDeletion: TaskStatus? = nil,
        enableFocus: Bool = true,
        preferredPet: PetType? = nil,
        sourceMemoID: UUID? = nil,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.dueDate = dueDate
        self.estimatedMinutes = estimatedMinutes
        self.spentMinutes = spentMinutes
        self.manualProgress = manualProgress
        self.status = status
        self.statusBeforeDeletion = statusBeforeDeletion
        self.enableFocus = enableFocus
        self.preferredPet = preferredPet
        self.sourceMemoID = sourceMemoID
        self.deletedAt = deletedAt
    }
}

extension TaskItem {
    var isDeleted: Bool {
        deletedAt != nil || status == .deleted
    }

    var computedProgress: Double {
        progress
    }

    var progress: Double {
        if let manualProgress {
            return manualProgress.clamped(to: 0 ... 1)
        }

        guard let estimatedMinutes, estimatedMinutes > 0 else {
            return 0
        }

        return (Double(spentMinutes) / Double(estimatedMinutes)).clamped(to: 0 ... 1)
    }

    var progressPercentage: Int {
        Int((progress * 100).rounded())
    }

    var progressText: String {
        "\(progressPercentage)%"
    }

    var isCompleted: Bool {
        !isDeleted && (status == .completed || progress >= 1)
    }

    func isOverdue(referenceDate: Date = .now) -> Bool {
        guard let dueDate else { return false }
        return !isCompleted && dueDate < referenceDate
    }

    func resolvedStatus(referenceDate: Date = .now) -> TaskStatus {
        if isDeleted {
            return .deleted
        }
        if isCompleted {
            return .completed
        }
        if status == .paused {
            return .paused
        }
        if status == .overdue {
            return .overdue
        }
        if let dueDate, dueDate < referenceDate, updatedAt <= dueDate {
            return .overdue
        }
        return .active
    }

    var shouldAppearInHistory: Bool {
        !isDeleted && isCompleted
    }

    var remainingMinutes: Int? {
        guard let estimatedMinutes else { return nil }
        return max(estimatedMinutes - spentMinutes, 0)
    }

    var remainingTimeText: String {
        guard let remainingMinutes else { return "剩余时间未知" }
        if remainingMinutes == 0 {
            return "预计时长已用完"
        }
        return "还差 \(remainingMinutes) 分钟"
    }

    var spentTimeText: String {
        "已投入 \(spentMinutes) 分钟"
    }

    var estimatedTimeText: String {
        guard let estimatedMinutes else { return "未设置预估时长" }
        return "预估 \(estimatedMinutes) 分钟"
    }

    var dueDateText: String {
        guard let dueDate else { return "未设置截止时间" }
        return DateDisplayFormatter.fullChineseDate(from: dueDate)
    }

    func countdownText(referenceDate: Date = .now) -> String {
        guard let dueDate else { return "未设置截止时间" }
        if isCompleted {
            return "已完成"
        }
        return DateDisplayFormatter.taskDueText(from: dueDate, now: referenceDate)
    }

    var statusText: String {
        resolvedStatus().displayName
    }

    var notesPreview: String? {
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.count <= 48 {
            return trimmed
        }
        return String(trimmed.prefix(48)) + "..."
    }

    var preferredPetText: String? {
        preferredPet?.displayName
    }

    var progressSummaryText: String {
        if let estimatedMinutes {
            return "\(progressText) · 已投入 \(spentMinutes)/\(estimatedMinutes) 分钟"
        }
        if spentMinutes > 0 {
            return "\(progressText) · 已投入 \(spentMinutes) 分钟"
        }
        return progressText
    }

    var dueSummaryText: String? {
        guard !isDeleted, dueDate != nil else { return nil }
        return countdownText()
    }

    var deletedAtText: String {
        guard let deletedAt else { return "" }
        return DateDisplayFormatter.deletedMemoText(from: deletedAt)
    }

    func addingSpentMinutes(_ minutes: Int, referenceDate: Date = .now) -> TaskItem {
        guard minutes > 0 else { return self }

        var updated = self
        updated.spentMinutes += minutes
        updated.updatedAt = referenceDate

        if updated.progress >= 1 {
            updated.status = .completed
        } else if updated.status == .completed {
            updated.status = .active
        }

        return updated
    }

    func settingManualProgress(_ value: Double?, referenceDate: Date = .now) -> TaskItem {
        var updated = self
        updated.manualProgress = value?.clamped(to: 0 ... 1)
        updated.updatedAt = referenceDate
        updated.status = updated.progress >= 1 ? .completed : .active
        return updated
    }

    func updating(
        title: String,
        notes: String,
        dueDate: Date?,
        estimatedMinutes: Int?,
        manualProgress: Double?,
        enableFocus: Bool,
        preferredPet: PetType?,
        referenceDate: Date = .now
    ) -> TaskItem {
        var updated = self
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.dueDate = dueDate
        updated.estimatedMinutes = estimatedMinutes
        updated.manualProgress = manualProgress?.clamped(to: 0 ... 1)
        updated.enableFocus = enableFocus
        updated.preferredPet = preferredPet
        updated.updatedAt = referenceDate

        if updated.progress >= 1 {
            updated.status = .completed
        } else if updated.status == .completed {
            updated.status = .active
        }

        return updated
    }

    func updatingSpentMinutes(_ spentMinutes: Int, referenceDate: Date = .now) -> TaskItem {
        var updated = self
        updated.spentMinutes = max(spentMinutes, 0)
        updated.updatedAt = referenceDate

        if updated.progress >= 1 {
            updated.status = .completed
        } else if updated.status == .completed {
            updated.status = .active
        }

        return updated
    }

    func withStatus(_ status: TaskStatus, referenceDate: Date = .now) -> TaskItem {
        var updated = self
        updated.status = status
        updated.updatedAt = referenceDate
        return updated
    }

    func markedCompleted(referenceDate: Date = .now) -> TaskItem {
        var updated = self
        updated.manualProgress = 1
        updated.status = .completed
        updated.updatedAt = referenceDate
        return updated
    }

    func reactivating(referenceDate: Date = .now) -> TaskItem {
        var updated = self
        updated.status = .active
        updated.updatedAt = referenceDate
        return updated
    }

    func applyingFocusProgressFeedback(step: Double = 0.1, referenceDate: Date = .now) -> TaskItem {
        var updated = self
        let baseProgress = manualProgress ?? progress
        updated.manualProgress = (baseProgress + step).clamped(to: 0 ... 1)
        updated.updatedAt = referenceDate
        updated.status = updated.progress >= 1 ? .completed : .active
        return updated
    }

    func softDeleting(referenceDate: Date = .now) -> TaskItem {
        var updated = self
        updated.statusBeforeDeletion = resolvedStatus(referenceDate: referenceDate)
        updated.status = .deleted
        updated.deletedAt = referenceDate
        updated.updatedAt = referenceDate
        return updated
    }

    func restoring(referenceDate: Date = .now) -> TaskItem {
        var updated = self
        updated.status = statusBeforeDeletion ?? .active
        updated.statusBeforeDeletion = nil
        updated.deletedAt = nil
        updated.updatedAt = referenceDate
        return updated
    }
}

typealias Task = TaskItem
