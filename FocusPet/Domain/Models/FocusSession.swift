import Foundation

struct FocusSession: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    // Optional when the user starts a free focus session with no linked task.
    var taskID: UUID?
    var petType: PetType
    var sceneType: SceneType
    let startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int
    var timerMode: TimerMode
    var plannedDurationSeconds: Int?
    var sessionStatus: FocusSessionStatus

    init(
        id: UUID = UUID(),
        taskID: UUID? = nil,
        petType: PetType,
        sceneType: SceneType,
        startedAt: Date = .now,
        endedAt: Date? = nil,
        durationSeconds: Int = 0,
        timerMode: TimerMode,
        plannedDurationSeconds: Int? = nil,
        sessionStatus: FocusSessionStatus = .finished
    ) {
        self.id = id
        self.taskID = taskID
        self.petType = petType
        self.sceneType = sceneType
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.timerMode = timerMode
        self.plannedDurationSeconds = plannedDurationSeconds
        self.sessionStatus = sessionStatus
    }
}

extension FocusSession {
    var durationMinutes: Int {
        durationSeconds / 60
    }

    var isFinished: Bool {
        sessionStatus == .finished
    }

    var durationText: String {
        Self.formattedDuration(durationSeconds)
    }

    var startedAtText: String {
        DateDisplayFormatter.relativeChineseDateTime(from: startedAt)
    }

    var plannedDurationText: String {
        guard let plannedDurationSeconds else { return "自由时长" }
        return Self.formattedDuration(plannedDurationSeconds)
    }

    var remainingDurationText: String {
        guard let plannedDurationSeconds else { return "未限制" }
        let remaining = max(plannedDurationSeconds - durationSeconds, 0)
        return Self.formattedDuration(remaining)
    }

    var historyTimestampText: String {
        DateDisplayFormatter.relativeChineseDateTime(from: startedAt)
    }

    static func formattedDuration(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}
