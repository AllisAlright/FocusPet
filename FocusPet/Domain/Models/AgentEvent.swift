import Foundation

enum AgentEventType: String, Codable, CaseIterable, Sendable {
    case focusStarted = "focus_started"
    case focusEnded = "focus_ended"
    case taskCreated = "task_created"
    case taskCompleted = "task_completed"
    case taskReactivated = "task_reactivated"
    case homeOpened = "home_opened"
}

struct AgentEvent: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let type: AgentEventType
    let createdAt: Date
    let taskID: UUID?
    let focusSessionID: UUID?

    init(
        id: UUID = UUID(),
        type: AgentEventType,
        createdAt: Date = .now,
        taskID: UUID? = nil,
        focusSessionID: UUID? = nil
    ) {
        self.id = id
        self.type = type
        self.createdAt = createdAt
        self.taskID = taskID
        self.focusSessionID = focusSessionID
    }
}
