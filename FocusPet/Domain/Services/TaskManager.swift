import Foundation

struct TaskMutation {
    let task: TaskItem
    let didComplete: Bool
    let didReactivate: Bool
}

struct TaskManager {
    func canStartFocus(task: TaskItem?) -> Bool {
        guard let task else { return true }
        return task.enableFocus && task.resolvedStatus() == .active
    }

    func normalizedStatus(for task: TaskItem, referenceDate: Date = .now) -> TaskStatus {
        task.resolvedStatus(referenceDate: referenceDate)
    }

    func createTask(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        estimatedMinutes: Int? = nil,
        spentMinutes: Int = 0,
        manualProgress: Double? = nil,
        enableFocus: Bool = true,
        preferredPet: PetType? = nil,
        status: TaskStatus = .active,
        sourceMemoID: UUID? = nil,
        referenceDate: Date = .now
    ) -> TaskItem? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }

        let task = TaskItem(
            title: trimmedTitle,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: referenceDate,
            updatedAt: referenceDate,
            dueDate: dueDate,
            estimatedMinutes: normalizedEstimate(estimatedMinutes),
            spentMinutes: max(spentMinutes, 0),
            manualProgress: normalizedManualProgress(manualProgress),
            status: status,
            enableFocus: enableFocus,
            preferredPet: preferredPet,
            sourceMemoID: sourceMemoID
        )

        return reconcile(task, referenceDate: referenceDate)
    }

    func updateTask(
        _ task: TaskItem,
        title: String,
        notes: String,
        dueDate: Date?,
        estimatedMinutes: Int?,
        spentMinutes: Int,
        manualProgress: Double?,
        enableFocus: Bool,
        preferredPet: PetType?,
        requestedStatus: TaskStatus,
        referenceDate: Date = .now
    ) -> TaskMutation {
        let previousStatus = task.resolvedStatus(referenceDate: referenceDate)

        var updated = task
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.dueDate = dueDate
        updated.estimatedMinutes = normalizedEstimate(estimatedMinutes)
        updated.spentMinutes = max(spentMinutes, 0)
        updated.manualProgress = normalizedManualProgress(manualProgress)
        updated.enableFocus = enableFocus
        updated.preferredPet = preferredPet
        updated.updatedAt = referenceDate

        if updated.isDeleted {
            updated.status = .deleted
        } else if updated.progress >= 1 {
            updated.status = .completed
        } else {
            switch requestedStatus {
            case .paused:
                updated.status = .paused
            case .deleted:
                updated.status = .deleted
            default:
                updated.status = .active
            }
        }

        let reconciled = reconcile(updated, referenceDate: referenceDate)
        return TaskMutation(
            task: reconciled,
            didComplete: previousStatus != .completed && reconciled.resolvedStatus(referenceDate: referenceDate) == .completed,
            didReactivate: false
        )
    }

    func pauseTask(_ task: TaskItem, referenceDate: Date = .now) -> TaskMutation {
        mutateStatus(task, status: .paused, referenceDate: referenceDate)
    }

    func reactivateTask(_ task: TaskItem, referenceDate: Date = .now) -> TaskMutation {
        let previousStatus = task.resolvedStatus(referenceDate: referenceDate)
        guard previousStatus == .paused || previousStatus == .overdue else {
            return TaskMutation(task: reconcile(task, referenceDate: referenceDate), didComplete: false, didReactivate: false)
        }

        var updated = task
        updated.status = .active
        updated.updatedAt = referenceDate

        return TaskMutation(
            task: reconcile(updated, referenceDate: referenceDate),
            didComplete: false,
            didReactivate: true
        )
    }

    func completeTask(_ task: TaskItem, referenceDate: Date = .now) -> TaskMutation {
        let previousStatus = task.resolvedStatus(referenceDate: referenceDate)

        var updated = task
        updated.manualProgress = 1
        updated.status = .completed
        updated.updatedAt = referenceDate

        return TaskMutation(
            task: reconcile(updated, referenceDate: referenceDate),
            didComplete: previousStatus != .completed,
            didReactivate: false
        )
    }

    func updateManualProgress(_ task: TaskItem, manualProgress: Double?, referenceDate: Date = .now) -> TaskMutation {
        updateTask(
            task,
            title: task.title,
            notes: task.notes,
            dueDate: task.dueDate,
            estimatedMinutes: task.estimatedMinutes,
            spentMinutes: task.spentMinutes,
            manualProgress: manualProgress,
            enableFocus: task.enableFocus,
            preferredPet: task.preferredPet,
            requestedStatus: task.status,
            referenceDate: referenceDate
        )
    }

    func updateSpentMinutes(_ task: TaskItem, spentMinutes: Int, referenceDate: Date = .now) -> TaskMutation {
        updateTask(
            task,
            title: task.title,
            notes: task.notes,
            dueDate: task.dueDate,
            estimatedMinutes: task.estimatedMinutes,
            spentMinutes: spentMinutes,
            manualProgress: task.manualProgress,
            enableFocus: task.enableFocus,
            preferredPet: task.preferredPet,
            requestedStatus: task.status,
            referenceDate: referenceDate
        )
    }

    func softDeleteTask(_ task: TaskItem, referenceDate: Date = .now) -> TaskItem {
        var updated = task
        updated.statusBeforeDeletion = task.resolvedStatus(referenceDate: referenceDate)
        updated.status = .deleted
        updated.deletedAt = referenceDate
        updated.updatedAt = referenceDate
        return updated
    }

    func restoreTask(_ task: TaskItem, referenceDate: Date = .now) -> TaskItem {
        var updated = task
        updated.deletedAt = nil
        updated.status = restoredStatus(for: task)
        updated.statusBeforeDeletion = nil
        updated.updatedAt = referenceDate
        return reconcile(updated, referenceDate: referenceDate)
    }

    func applyFocusSession(
        to task: TaskItem,
        durationSeconds: Int,
        didAdvance: Bool,
        referenceDate: Date = .now
    ) -> TaskMutation {
        guard canStartFocus(task: task) else {
            return TaskMutation(task: reconcile(task, referenceDate: referenceDate), didComplete: false, didReactivate: false)
        }

        let previousStatus = task.resolvedStatus(referenceDate: referenceDate)
        var updated = task
        let addedMinutes = max(Int(ceil(Double(max(durationSeconds, 0)) / 60.0)), durationSeconds > 0 ? 1 : 0)
        updated.spentMinutes += addedMinutes
        updated.updatedAt = referenceDate

        if updated.progress >= 1 {
            updated.status = .completed
        } else {
            updated.status = .active
        }

        if didAdvance, updated.estimatedMinutes == nil {
            let baseProgress = updated.manualProgress ?? updated.progress
            updated.manualProgress = (baseProgress + 0.1).clamped(to: 0 ... 1)
            if updated.progress >= 1 {
                updated.status = .completed
            }
        }

        let reconciled = reconcile(updated, referenceDate: referenceDate)
        return TaskMutation(
            task: reconciled,
            didComplete: previousStatus != .completed && reconciled.resolvedStatus(referenceDate: referenceDate) == .completed,
            didReactivate: false
        )
    }

    private func mutateStatus(_ task: TaskItem, status: TaskStatus, referenceDate: Date) -> TaskMutation {
        let previousStatus = task.resolvedStatus(referenceDate: referenceDate)
        var updated = task
        updated.status = status
        updated.updatedAt = referenceDate
        let reconciled = reconcile(updated, referenceDate: referenceDate)
        return TaskMutation(
            task: reconciled,
            didComplete: previousStatus != .completed && reconciled.resolvedStatus(referenceDate: referenceDate) == .completed,
            didReactivate: false
        )
    }

    private func restoredStatus(for task: TaskItem) -> TaskStatus {
        switch task.statusBeforeDeletion {
        case .paused:
            return .paused
        case .completed:
            return .completed
        case .overdue:
            return .overdue
        default:
            return .active
        }
    }

    private func reconcile(_ task: TaskItem, referenceDate: Date) -> TaskItem {
        var updated = task

        if updated.deletedAt != nil {
            updated.status = .deleted
            return updated
        }

        if updated.progress >= 1 {
            updated.status = .completed
            return updated
        }

        switch updated.status {
        case .paused:
            return updated
        case .overdue:
            return updated
        case .completed:
            updated.status = .active
        case .deleted:
            updated.status = .active
        case .active:
            if isOverdue(task: updated, referenceDate: referenceDate) {
                updated.status = .overdue
            } else {
                updated.status = .active
            }
        }

        return updated
    }

    private func isOverdue(task: TaskItem, referenceDate: Date) -> Bool {
        guard let dueDate = task.dueDate else { return false }
        guard task.status != .paused, task.deletedAt == nil, task.progress < 1 else { return false }
        return dueDate < referenceDate && task.updatedAt <= dueDate
    }

    private func normalizedEstimate(_ estimatedMinutes: Int?) -> Int? {
        guard let estimatedMinutes else { return nil }
        return max(estimatedMinutes, 5)
    }

    private func normalizedManualProgress(_ manualProgress: Double?) -> Double? {
        manualProgress?.clamped(to: 0 ... 1)
    }
}
