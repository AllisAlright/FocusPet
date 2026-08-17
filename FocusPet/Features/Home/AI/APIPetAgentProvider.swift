import Foundation

protocol PetAgentProviding: Sendable {
    func sendMessage(
        _ input: String,
        petType: PetType,
        conversationTurnCount: Int,
        tasks: [TaskItem],
        focusSessions: [FocusSession]
    ) async throws -> PetAgentResponse
}

struct PetAgentResponse: Decodable, Sendable {
    let intent: String
    let safetyLevel: String
    let shouldCallSkill: Bool
    let skill: String?
    let requiresConfirmation: Bool
    let message: String
    let tasks: [String]
    let recommendation: PetAgentNextActionRecommendation?
    let review: PetAgentWeeklyReview?

    enum CodingKeys: String, CodingKey {
        case intent
        case safetyLevel = "safety_level"
        case shouldCallSkill = "should_call_skill"
        case skill
        case requiresConfirmation = "requires_confirmation"
        case message
        case tasks
        case recommendation
        case review
    }
}

struct PetAgentNextActionRecommendation: Decodable, Sendable {
    let taskID: String?
    let action: String
    let reason: String
    let suggestedFocusMinutes: Int

    enum CodingKeys: String, CodingKey {
        case taskID = "task_id"
        case action
        case reason
        case suggestedFocusMinutes = "suggested_focus_minutes"
    }
}

struct PetAgentWeeklyReview: Decodable, Sendable {
    let summary: String
    let observation: String
    let petComment: String

    enum CodingKeys: String, CodingKey {
        case summary
        case observation
        case petComment = "pet_comment"
    }
}

private struct PetAgentRequest: Encodable {
    let userInput: String
    let petType: String
    let conversationTurnCount: Int
    let tasks: [PetAgentTaskSummary]
    let reviewStats: PetAgentReviewStats
    let todayFocusMinutes: Int

    enum CodingKeys: String, CodingKey {
        case userInput = "user_input"
        case petType = "pet_type"
        case conversationTurnCount = "conversation_turn_count"
        case tasks
        case reviewStats = "review_stats"
        case todayFocusMinutes = "today_focus_minutes"
    }
}

private struct PetAgentTaskSummary: Encodable {
    let id: String
    let title: String
    let status: String
    let progress: Double
    let dueDate: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case status
        case progress
        case dueDate = "due_date"
        case updatedAt = "updated_at"
    }
}

private struct PetAgentReviewStats: Encodable {
    let totalFocusMinutes: Int
    let sessionCount: Int
    let lateNightSessionCount: Int
    let mostActiveTimeBucket: String?
    let topTaskTitle: String?
    let longestSessionMinutes: Int

    enum CodingKeys: String, CodingKey {
        case totalFocusMinutes = "total_focus_minutes"
        case sessionCount = "session_count"
        case lateNightSessionCount = "late_night_session_count"
        case mostActiveTimeBucket = "most_active_time_bucket"
        case topTaskTitle = "top_task_title"
        case longestSessionMinutes = "longest_session_minutes"
    }
}

struct APIPetAgentProvider: PetAgentProviding {
    private let baseURL: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    nonisolated init(
        baseURL: URL = FocusPetAPIConfig.baseURL,
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    nonisolated func sendMessage(
        _ input: String,
        petType: PetType,
        conversationTurnCount: Int,
        tasks: [TaskItem],
        focusSessions: [FocusSession]
    ) async throws -> PetAgentResponse {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            throw SplitTaskAPIError.invalidResponse
        }

        let requestBody = PetAgentRequest(
            userInput: trimmedInput,
            petType: petType.rawValue,
            conversationTurnCount: conversationTurnCount,
            tasks: makeTaskSummaries(from: tasks),
            reviewStats: makeReviewStats(from: focusSessions, tasks: tasks),
            todayFocusMinutes: todayFocusMinutes(from: focusSessions)
        )
        let endpoint = baseURL.appending(path: "api/v1/ai/agent-message")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SplitTaskAPIError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw try decodeServerError(from: data)
        }

        return try decoder.decode(PetAgentResponse.self, from: data)
    }

    private nonisolated func makeTaskSummaries(from tasks: [TaskItem]) -> [PetAgentTaskSummary] {
        tasks
            .filter { !$0.isDeleted }
            .map { task in
                PetAgentTaskSummary(
                    id: task.id.uuidString,
                    title: task.title,
                    status: agentStatus(for: task),
                    progress: task.progress,
                    dueDate: formattedDate(task.dueDate),
                    updatedAt: formattedDate(task.updatedAt)
                )
            }
    }

    private nonisolated func agentStatus(for task: TaskItem) -> String {
        if task.isCompleted {
            return "completed"
        }
        if task.resolvedStatus() == .paused {
            return "paused"
        }
        if task.resolvedStatus() == .overdue {
            return "overdue"
        }
        if task.progress > 0 {
            return "in_progress"
        }
        return "todo"
    }

    private nonisolated func makeReviewStats(
        from sessions: [FocusSession],
        tasks: [TaskItem]
    ) -> PetAgentReviewStats {
        let calendar = Calendar.current
        let since = calendar.date(byAdding: .day, value: -7, to: Date.now) ?? Date.now
        let recentSessions = sessions.filter { $0.startedAt >= since && $0.isFinished }
        let totalMinutes = recentSessions.map(\.durationMinutes).reduce(0, +)
        let lateNightCount = recentSessions.filter {
            let hour = calendar.component(.hour, from: $0.startedAt)
            return hour >= 23 || hour < 5
        }.count

        return PetAgentReviewStats(
            totalFocusMinutes: totalMinutes,
            sessionCount: recentSessions.count,
            lateNightSessionCount: lateNightCount,
            mostActiveTimeBucket: mostActiveTimeBucket(from: recentSessions),
            topTaskTitle: topTaskTitle(from: recentSessions, tasks: tasks),
            longestSessionMinutes: recentSessions.map(\.durationMinutes).max() ?? 0
        )
    }

    private nonisolated func todayFocusMinutes(from sessions: [FocusSession]) -> Int {
        sessions
            .filter { Calendar.current.isDateInToday($0.startedAt) }
            .map(\.durationMinutes)
            .reduce(0, +)
    }

    private nonisolated func mostActiveTimeBucket(from sessions: [FocusSession]) -> String? {
        let buckets = Dictionary(grouping: sessions) { session -> String in
            let hour = Calendar.current.component(.hour, from: session.startedAt)
            switch hour {
            case 5 ..< 11:
                return "morning"
            case 11 ..< 18:
                return "afternoon"
            case 18 ..< 23:
                return "evening"
            default:
                return "late_night"
            }
        }

        return buckets
            .mapValues { $0.count }
            .max(by: { $0.value < $1.value })?
            .key
    }

    private nonisolated func topTaskTitle(
        from sessions: [FocusSession],
        tasks: [TaskItem]
    ) -> String? {
        let taskMinutes = Dictionary(grouping: sessions.compactMap { session -> (UUID, Int)? in
            guard let taskID = session.taskID else { return nil }
            return (taskID, session.durationMinutes)
        }, by: { $0.0 })
        .mapValues { entries in
            entries.map(\.1).reduce(0, +)
        }

        guard let topTaskID = taskMinutes.max(by: { $0.value < $1.value })?.key else {
            return nil
        }

        return tasks.first { $0.id == topTaskID }?.title
    }

    private nonisolated func formattedDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        return ISO8601DateFormatter().string(from: date)
    }

    private nonisolated func decodeServerError(from data: Data) throws -> SplitTaskAPIError {
        if let message = try? decoder.decode(APIErrorMessage.self, from: data).detail,
           !message.isEmpty {
            return .serverMessage(message)
        }

        return .serverMessage("这次整理没有成功，再试一次就好。")
    }
}

private struct APIErrorMessage: Decodable {
    let detail: String
}
