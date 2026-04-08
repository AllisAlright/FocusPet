import Foundation

struct FocusSessionMutation {
    let session: FocusSession
    let taskMutation: TaskMutation?
}

struct FocusManager {
    private let taskManager = TaskManager()

    func canStartFocus(task: TaskItem?) -> Bool {
        taskManager.canStartFocus(task: task)
    }

    func finalizeSession(
        _ session: FocusSession,
        task: TaskItem?,
        didAdvance: Bool,
        referenceDate: Date = .now
    ) -> FocusSessionMutation {
        let finalizedSession = finalized(session, referenceDate: referenceDate)

        guard let task else {
            return FocusSessionMutation(session: finalizedSession, taskMutation: nil)
        }

        let taskMutation = taskManager.applyFocusSession(
            to: task,
            durationSeconds: finalizedSession.durationSeconds,
            didAdvance: didAdvance,
            referenceDate: finalizedSession.endedAt ?? referenceDate
        )
        return FocusSessionMutation(session: finalizedSession, taskMutation: taskMutation)
    }

    private func finalized(_ session: FocusSession, referenceDate: Date) -> FocusSession {
        var updated = session
        updated.endedAt = updated.endedAt ?? referenceDate
        updated.durationSeconds = max(updated.durationSeconds, 0)
        updated.sessionStatus = .finished
        return updated
    }
}
