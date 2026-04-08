import Combine
import Foundation

struct TaskRecommendation: Equatable {
    enum Kind: Equatable {
        case continueTask
        case reactivateTask
        case empty
    }

    let kind: Kind
    let title: String
    let message: String
    let taskID: UUID?
}

@MainActor
final class FocusPetStore: ObservableObject {
    @Published var tasks: [TaskItem]
    @Published var memoItems: [MemoItem]
    @Published var focusSessions: [FocusSession]
    @Published var settings: AppSettings
    @Published private(set) var agentEvents: [AgentEvent] = []

    private let taskManager = TaskManager()
    private let focusManager = FocusManager()

    convenience init() {
        self.init(
            tasks: FocusPetMockData.tasks,
            memoItems: FocusPetMockData.memoItems,
            focusSessions: FocusPetMockData.focusSessions,
            settings: FocusPetMockData.appSettings
        )
    }

    init(
        tasks: [TaskItem],
        memoItems: [MemoItem],
        focusSessions: [FocusSession],
        settings: AppSettings
    ) {
        self.tasks = tasks
        self.memoItems = memoItems
        self.focusSessions = focusSessions
        self.settings = settings
        removeExpiredDeletedTasksIfNeeded()
        removeExpiredDeletedMemosIfNeeded()
        applyTaskSortIfNeeded()
        applyMemoSortIfNeeded()
    }

    func task(with id: UUID?) -> TaskItem? {
        guard let id else { return nil }
        return tasks.first { $0.id == id }
    }

    func canStartFocus(taskID: UUID?) -> Bool {
        focusManager.canStartFocus(task: task(with: taskID))
    }

    var visibleTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted && !$0.isDeleted }
    }

    var currentTasks: [TaskItem] {
        tasks.filter { $0.resolvedStatus() == .active && !$0.isDeleted }
    }

    private var suggestedCurrentTask: TaskItem? {
        let activeTasks = currentTasks
        guard !activeTasks.isEmpty else { return nil }

        if let nearestDue = activeTasks
            .filter({ $0.dueDate != nil })
            .sorted(by: { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) })
            .first {
            return nearestDue
        }

        if let mostRecentlyEdited = activeTasks.sorted(by: { $0.updatedAt > $1.updatedAt }).first {
            return mostRecentlyEdited
        }

        if let highestProgress = activeTasks
            .sorted(by: {
                if $0.progress == $1.progress {
                    return $0.updatedAt > $1.updatedAt
                }
                return $0.progress > $1.progress
            })
            .first,
           highestProgress.progress > 0 {
            return highestProgress
        }

        return activeTasks.sorted(by: { $0.updatedAt > $1.updatedAt }).first
    }

    var taskRecommendation: TaskRecommendation {
        if let task = suggestedCurrentTask {
            return TaskRecommendation(
                kind: .continueTask,
                title: "继续推进",
                message: "试着把「\(task.title)」往前推一点。",
                taskID: task.id
            )
        }

        if let task = pausedTasks.sorted(by: { $0.updatedAt > $1.updatedAt }).first
            ?? overdueTasks
                .sorted(by: {
                    if ($0.dueDate ?? .distantFuture) == ($1.dueDate ?? .distantFuture) {
                        return $0.updatedAt > $1.updatedAt
                    }
                    return ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture)
                })
                .first {
            return TaskRecommendation(
                kind: .reactivateTask,
                title: "重新捡起",
                message: "把「\(task.title)」重新捡起来也很好。",
                taskID: task.id
            )
        }

        return TaskRecommendation(
            kind: .empty,
            title: "慢慢开始",
            message: "今天先写下一件想做的事吧。",
            taskID: nil
        )
    }

    var activeTasks: [TaskItem] {
        visibleTasks.filter { $0.resolvedStatus() == .active }
    }

    var focusEligibleTasks: [TaskItem] {
        activeTasks.filter(\.enableFocus)
    }

    var recommendedFocusTasks: [TaskItem] {
        let eligibleTasks = focusEligibleTasks
        guard !eligibleTasks.isEmpty else { return [] }

        let recentlyFocusedTaskIDs = focusSessions.compactMap(\.taskID)

        return eligibleTasks.sorted { lhs, rhs in
            let lhsDue = lhs.dueDate ?? .distantFuture
            let rhsDue = rhs.dueDate ?? .distantFuture
            if lhsDue != rhsDue {
                return lhsDue < rhsDue
            }

            let lhsFocusIndex = recentlyFocusedTaskIDs.firstIndex(of: lhs.id) ?? .max
            let rhsFocusIndex = recentlyFocusedTaskIDs.firstIndex(of: rhs.id) ?? .max
            if lhsFocusIndex != rhsFocusIndex {
                return lhsFocusIndex < rhsFocusIndex
            }

            if lhs.updatedAt != rhs.updatedAt {
                return lhs.updatedAt > rhs.updatedAt
            }

            if lhs.progress != rhs.progress {
                return lhs.progress > rhs.progress
            }

            return lhs.createdAt > rhs.createdAt
        }
    }

    var pausedTasks: [TaskItem] {
        visibleTasks.filter { $0.resolvedStatus() == .paused }
    }

    var overdueTasks: [TaskItem] {
        visibleTasks.filter { $0.resolvedStatus() == .overdue }
    }

    var completedTasks: [TaskItem] {
        tasks.filter { $0.isCompleted && !$0.isDeleted }.sorted { $0.updatedAt > $1.updatedAt }
    }

    var unfinishedHistoryTasks: [TaskItem] {
        tasks
            .filter {
                guard !$0.isDeleted else { return false }
                let status = $0.resolvedStatus()
                return status == .paused || status == .overdue
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var deletedTasks: [TaskItem] {
        tasks
            .filter(\.isDeleted)
            .sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    var homeSummary: HomeSummary {
        let nearestDueTaskTitle = tasks
            .filter { !$0.isCompleted && !$0.isDeleted }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .first?
            .title

        return HomeSummary(
            petType: settings.defaultPet,
            activeTaskCount: tasks.filter { $0.resolvedStatus() == .active }.count,
            overdueTaskCount: tasks.filter { $0.resolvedStatus() == .overdue }.count,
            todayFocusMinutes: focusSessions
                .filter { Calendar.current.isDateInToday($0.startedAt) }
                .map(\.durationMinutes)
                .reduce(0, +),
            nearestDueTaskTitle: nearestDueTaskTitle,
            message: "先推进一点，也算前进。"
        )
    }

    func recordAgentEvent(_ type: AgentEventType, taskID: UUID? = nil, focusSessionID: UUID? = nil) {
        agentEvents.insert(
            AgentEvent(type: type, taskID: taskID, focusSessionID: focusSessionID),
            at: 0
        )
    }

    func registerHomeOpened() {
        recordAgentEvent(.homeOpened)
    }

    func registerFocusStarted(taskID: UUID?, sessionID: UUID? = nil) {
        recordAgentEvent(.focusStarted, taskID: taskID, focusSessionID: sessionID)
    }

    func finishFocusSession(_ session: FocusSession, didAdvance: Bool) {
        let mutation = focusManager.finalizeSession(
            session,
            task: task(with: session.taskID),
            didAdvance: didAdvance,
            referenceDate: session.endedAt ?? .now
        )
        focusSessions.insert(mutation.session, at: 0)
        recordAgentEvent(.focusEnded, taskID: mutation.session.taskID, focusSessionID: mutation.session.id)

        if let taskMutation = mutation.taskMutation {
            replaceTask(taskMutation.task)
            if taskMutation.didComplete {
                recordAgentEvent(.taskCompleted, taskID: taskMutation.task.id, focusSessionID: mutation.session.id)
            }
        }
    }

    func updateDefaultPet(_ pet: PetType) {
        settings.defaultPet = pet
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
        sourceMemoID: UUID? = nil
    ) -> UUID? {
        guard let task = taskManager.createTask(
            title: title,
            notes: notes,
            dueDate: dueDate,
            estimatedMinutes: estimatedMinutes,
            spentMinutes: spentMinutes,
            manualProgress: manualProgress,
            enableFocus: enableFocus,
            preferredPet: preferredPet,
            status: status,
            sourceMemoID: sourceMemoID
        ) else {
            return nil
        }

        tasks.insert(task, at: 0)
        sortTasks()
        recordAgentEvent(.taskCreated, taskID: task.id)
        if task.resolvedStatus() == .completed {
            recordAgentEvent(.taskCompleted, taskID: task.id)
        }
        return task.id
    }

    func updateTask(
        id: UUID,
        title: String,
        notes: String,
        dueDate: Date?,
        estimatedMinutes: Int?,
        manualProgress: Double?,
        enableFocus: Bool,
        preferredPet: PetType?
    ) {
        guard let task = task(with: id) else { return }
        let mutation = taskManager.updateTask(
            task,
            title: title,
            notes: notes,
            dueDate: dueDate,
            estimatedMinutes: estimatedMinutes,
            spentMinutes: task.spentMinutes,
            manualProgress: manualProgress,
            enableFocus: enableFocus,
            preferredPet: preferredPet,
            requestedStatus: task.status
        )
        replaceTask(mutation.task)
        if mutation.didComplete {
            recordAgentEvent(.taskCompleted, taskID: mutation.task.id)
        }
    }

    func updateTask(
        id: UUID,
        title: String,
        notes: String,
        dueDate: Date?,
        estimatedMinutes: Int?,
        spentMinutes: Int,
        manualProgress: Double?,
        enableFocus: Bool,
        preferredPet: PetType?,
        status: TaskStatus
    ) {
        guard let task = task(with: id) else { return }
        let mutation = taskManager.updateTask(
            task,
            title: title,
            notes: notes,
            dueDate: dueDate,
            estimatedMinutes: estimatedMinutes,
            spentMinutes: spentMinutes,
            manualProgress: manualProgress,
            enableFocus: enableFocus,
            preferredPet: preferredPet,
            requestedStatus: status
        )
        replaceTask(mutation.task)
        if mutation.didComplete {
            recordAgentEvent(.taskCompleted, taskID: mutation.task.id)
        }
    }

    func pauseTask(id: UUID) {
        guard let task = task(with: id) else { return }
        replaceTask(taskManager.pauseTask(task).task)
    }

    func resumeTask(id: UUID) {
        reactivateTask(id: id)
    }

    func reactivateTask(id: UUID) {
        guard let task = task(with: id) else { return }
        let mutation = taskManager.reactivateTask(task)
        replaceTask(mutation.task)
        if mutation.didReactivate {
            recordAgentEvent(.taskReactivated, taskID: mutation.task.id)
        }
    }

    func completeTask(id: UUID) {
        guard let task = task(with: id) else { return }
        let mutation = taskManager.completeTask(task)
        replaceTask(mutation.task)
        if mutation.didComplete {
            recordAgentEvent(.taskCompleted, taskID: mutation.task.id)
        }
    }

    func updateTaskProgress(id: UUID, manualProgress: Double?) {
        guard let task = task(with: id) else { return }
        let mutation = taskManager.updateManualProgress(task, manualProgress: manualProgress)
        replaceTask(mutation.task)
        if mutation.didComplete {
            recordAgentEvent(.taskCompleted, taskID: mutation.task.id)
        }
    }

    func updateTaskSpentMinutes(id: UUID, spentMinutes: Int) {
        guard let task = task(with: id) else { return }
        let mutation = taskManager.updateSpentMinutes(task, spentMinutes: spentMinutes)
        replaceTask(mutation.task)
        if mutation.didComplete {
            recordAgentEvent(.taskCompleted, taskID: mutation.task.id)
        }
    }

    func deleteTask(id: UUID) {
        softDeleteTask(id: id)
    }

    func softDeleteTask(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id && !$0.isDeleted }) else { return }
        tasks[index] = taskManager.softDeleteTask(tasks[index])
        sortTasks()
    }

    func restoreTask(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id && $0.isDeleted }) else { return }
        tasks[index] = taskManager.restoreTask(tasks[index])
        sortTasks()
    }

    func permanentlyDeleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
    }

    func cleanupDeletedTasksIfNeeded() {
        let didRemoveExpired = removeExpiredDeletedTasksIfNeeded()
        if didRemoveExpired {
            applyTaskSortIfNeeded()
        }
    }

    func cleanupDeletedMemosIfNeeded() {
        let didRemoveExpired = removeExpiredDeletedMemosIfNeeded()
        if didRemoveExpired {
            applyMemoSortIfNeeded()
        }
    }

    func cleanupDeletedItemsIfNeeded() {
        cleanupDeletedTasksIfNeeded()
        cleanupDeletedMemosIfNeeded()
    }

    func convertMemoToTask(
        memoID: UUID,
        title: String? = nil,
        notes: String? = nil,
        dueDate: Date? = nil,
        estimatedMinutes: Int? = nil,
        enableFocus: Bool = true,
        preferredPet: PetType? = nil,
        deleteOriginalMemo: Bool = false
    ) -> UUID? {
        guard let memo = memo(with: memoID) else { return nil }
        let taskID = createTask(
            title: title ?? (memo.previewText.isEmpty ? "新的事项" : memo.previewText),
            notes: notes ?? memo.content,
            dueDate: dueDate,
            estimatedMinutes: estimatedMinutes,
            enableFocus: enableFocus,
            preferredPet: preferredPet,
            sourceMemoID: memo.id
        )

        if deleteOriginalMemo {
            softDeleteMemo(id: memo.id)
        }

        return taskID
    }

    func memo(with id: UUID) -> MemoItem? {
        memoItems.first { $0.id == id }
    }

    var activeMemoItems: [MemoItem] {
        memoItems.filter { !$0.isDeleted }
    }

    var deletedMemoItems: [MemoItem] {
        memoItems
            .filter(\.isDeleted)
            .sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    func createMemo(content: String, isPinned: Bool = false) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let memo = MemoItem(content: trimmed, isPinned: isPinned)
        memoItems.insert(memo, at: 0)
        sortMemos()
    }

    func updateMemo(id: UUID, content: String, isPinned: Bool) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = memoItems.firstIndex(where: { $0.id == id }) else { return }

        memoItems[index] = memoItems[index].updating(content: trimmed, isPinned: isPinned)
        sortMemos()
    }

    func softDeleteMemo(id: UUID) {
        guard let index = memoItems.firstIndex(where: { $0.id == id && !$0.isDeleted }) else { return }
        memoItems[index] = memoItems[index].softDeleting()
        sortMemos()
    }

    func restoreMemo(id: UUID) {
        guard let index = memoItems.firstIndex(where: { $0.id == id && $0.isDeleted }) else { return }
        memoItems[index] = memoItems[index].restoring()
        sortMemos()
    }

    func permanentlyDeleteMemo(id: UUID) {
        memoItems.removeAll { $0.id == id }
    }

    func togglePin(forMemoID id: UUID) {
        guard let index = memoItems.firstIndex(where: { $0.id == id }) else { return }
        memoItems[index].isPinned.toggle()
        memoItems[index].updatedAt = .now
        applyMemoSortIfNeeded()
    }

    @discardableResult
    private func removeExpiredDeletedTasksIfNeeded() -> Bool {
        let cutoff = Date.now.addingTimeInterval(-7 * 24 * 60 * 60)
        let filteredTasks = tasks.filter { task in
            guard let deletedAt = task.deletedAt else { return true }
            return deletedAt >= cutoff
        }
        guard filteredTasks.count != tasks.count else { return false }
        tasks = filteredTasks
        return true
    }

    @discardableResult
    private func removeExpiredDeletedMemosIfNeeded() -> Bool {
        let cutoff = Date.now.addingTimeInterval(-7 * 24 * 60 * 60)
        let filteredMemos = memoItems.filter { memo in
            guard let deletedAt = memo.deletedAt else { return true }
            return deletedAt >= cutoff
        }
        guard filteredMemos.count != memoItems.count else { return false }
        memoItems = filteredMemos
        return true
    }

    private func replaceTask(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        sortTasks()
    }

    private func sortTasks() {
        applyTaskSortIfNeeded()
    }

    private func applyTaskSortIfNeeded() {
        let sorted = sortedTasks()
        guard sorted != tasks else { return }
        tasks = sorted
    }

    private func sortedTasks() -> [TaskItem] {
        tasks.sorted {
            if $0.isDeleted != $1.isDeleted {
                return !$0.isDeleted && $1.isDeleted
            }

            if $0.isDeleted && $1.isDeleted {
                return ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast)
            }

            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted && $1.isCompleted
            }

            let lhsStatus = taskManager.normalizedStatus(for: $0)
            let rhsStatus = taskManager.normalizedStatus(for: $1)
            if lhsStatus != rhsStatus {
                return statusPriority(lhsStatus) < statusPriority(rhsStatus)
            }
            return $0.updatedAt > $1.updatedAt
        }
    }

    private func statusPriority(_ status: TaskStatus) -> Int {
        switch status {
        case .active:
            return 0
        case .overdue:
            return 1
        case .paused:
            return 2
        case .completed:
            return 3
        case .deleted:
            return 4
        }
    }

    private func sortMemos() {
        applyMemoSortIfNeeded()
    }

    private func applyMemoSortIfNeeded() {
        let sorted = sortedMemos()
        guard sorted != memoItems else { return }
        memoItems = sorted
    }

    private func sortedMemos() -> [MemoItem] {
        memoItems.sorted {
            if $0.isDeleted != $1.isDeleted {
                return !$0.isDeleted && $1.isDeleted
            }

            if $0.isDeleted && $1.isDeleted {
                return ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast)
            }

            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }
            return $0.updatedAt > $1.updatedAt
        }
    }
}
