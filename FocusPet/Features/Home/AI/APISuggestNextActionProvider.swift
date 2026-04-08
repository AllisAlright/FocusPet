import Foundation

protocol SuggestNextActionProviding: Sendable {
    func suggestNextAction(from tasks: [TaskItem], isManualRefresh: Bool) async throws -> String
}

// Request model for POST /api/v1/ai/suggest-next-action.
// The frontend selects one task locally, then sends only that target to the backend.
private struct SuggestNextActionRequest: Encodable {
    let task: SuggestNextActionTaskPayload
}

private struct SuggestNextActionTaskPayload: Encodable {
    let title: String
    let type: String
}

private enum SuggestionCategory: String, CaseIterable, Hashable {
    case inProgress = "in_progress"
    case todo = "todo"
    case overdue = "overdue"
    case paused = "paused"
}

private struct SuggestionCandidate {
    let id: UUID
    let title: String
    let category: SuggestionCategory
}

// Response model for POST /api/v1/ai/suggest-next-action.
private struct SuggestNextActionResponse: Decodable {
    let message: String
}

private struct SuggestNextActionAPIErrorResponse: Decodable {
    let detail: String
}

actor APISuggestNextActionProvider: SuggestNextActionProviding {
    private let baseURL: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // Selection state used to improve diversity between suggestions.
    private var lastSuggestedTaskID: UUID?
    private var lastCategory: SuggestionCategory?
    private var categoryIndices: [SuggestionCategory: Int] = [:]

    init(
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

    func suggestNextAction(from tasks: [TaskItem], isManualRefresh: Bool) async throws -> String {
        _ = isManualRefresh
        let pools = buildPools(from: tasks)
        let selectedTask = selectCandidate(from: pools)
        let requestBody = SuggestNextActionRequest(task: selectedTask)
        let endpoint = baseURL.appending(path: "api/v1/ai/suggest-next-action")

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

        let payload = try decoder.decode(SuggestNextActionResponse.self, from: data)
        return normalizeSuggestionMessage(payload.message, for: selectedTask.title)
    }

    // Build separate pools first so overdue and paused stay independent.
    private func buildPools(from tasks: [TaskItem]) -> [SuggestionCategory: [SuggestionCandidate]] {
        let activeTasks = tasks.filter { $0.resolvedStatus() == .active && !$0.isDeleted && !$0.isCompleted }
        let inProgressTasks = activeTasks
            .filter { $0.progress > 0 }
            .sorted(by: compareInProgressPriority)
            .map { SuggestionCandidate(id: $0.id, title: $0.title, category: .inProgress) }

        let todoTasks = activeTasks
            .filter { $0.progress == 0 }
            .sorted(by: compareShortTitlePriority)
            .map { SuggestionCandidate(id: $0.id, title: $0.title, category: .todo) }

        let overdueTasks = tasks
            .filter { $0.resolvedStatus() == .overdue && !$0.isDeleted && !$0.isCompleted }
            .sorted(by: compareOverduePriority)
            .map { SuggestionCandidate(id: $0.id, title: $0.title, category: .overdue) }

        let pausedTasks = tasks
            .filter { $0.resolvedStatus() == .paused && !$0.isDeleted && !$0.isCompleted }
            .sorted(by: compareShortTitlePriority)
            .map { SuggestionCandidate(id: $0.id, title: $0.title, category: .paused) }

        return [
            .inProgress: inProgressTasks,
            .todo: todoTasks,
            .overdue: overdueTasks,
            .paused: pausedTasks,
        ]
    }

    private func selectCandidate(from pools: [SuggestionCategory: [SuggestionCandidate]]) -> SuggestNextActionTaskPayload {
        let category = chooseCategory(from: pools)

        if let candidate = nextCandidate(in: category, pools: pools) {
            lastSuggestedTaskID = candidate.id
            lastCategory = candidate.category
            return SuggestNextActionTaskPayload(title: candidate.title, type: candidate.category.rawValue)
        }

        if let fallbackCandidate = nextCandidateFromOtherCategories(excluding: category, pools: pools) {
            lastSuggestedTaskID = fallbackCandidate.id
            lastCategory = fallbackCandidate.category
            return SuggestNextActionTaskPayload(title: fallbackCandidate.title, type: fallbackCandidate.category.rawValue)
        }

        return SuggestNextActionTaskPayload(title: "写下一件你最想推进的事", type: "none")
    }

    private func chooseCategory(from pools: [SuggestionCategory: [SuggestionCandidate]]) -> SuggestionCategory? {
        let hasInProgress = !(pools[.inProgress] ?? []).isEmpty
        let hasTodo = !(pools[.todo] ?? []).isEmpty
        let hasOverdue = !(pools[.overdue] ?? []).isEmpty
        let hasPaused = !(pools[.paused] ?? []).isEmpty

        if hasInProgress {
            return weightedCategoryChoice(
                candidates: [
                    (hasInProgress ? .inProgress : nil, 50),
                    (hasTodo ? .todo : nil, 30),
                    (hasOverdue ? .overdue : nil, 15),
                    (hasPaused ? .paused : nil, 5),
                ]
            )
        }

        if hasTodo {
            return weightedCategoryChoice(
                candidates: [
                    (hasTodo ? .todo : nil, 65),
                    (hasOverdue ? .overdue : nil, 25),
                    (hasPaused ? .paused : nil, 10),
                ]
            )
        }

        if hasOverdue {
            return .overdue
        }

        if hasPaused {
            return .paused
        }

        return nil
    }

    // Round-robin within each category, while avoiding the most recent task if possible.
    private func nextCandidate(
        in category: SuggestionCategory?,
        pools: [SuggestionCategory: [SuggestionCandidate]]
    ) -> SuggestionCandidate? {
        guard let category, let tasks = pools[category], !tasks.isEmpty else { return nil }

        let startIndex = categoryIndices[category, default: 0] % tasks.count
        for offset in 0 ..< tasks.count {
            let index = (startIndex + offset) % tasks.count
            let candidate = tasks[index]

            if candidate.id != lastSuggestedTaskID {
                categoryIndices[category] = (index + 1) % tasks.count
                return candidate
            }
        }

        return nil
    }

    private func nextCandidateFromOtherCategories(
        excluding excludedCategory: SuggestionCategory?,
        pools: [SuggestionCategory: [SuggestionCandidate]]
    ) -> SuggestionCandidate? {
        let categoryOrder = orderedFallbackCategories(excluding: excludedCategory)
        for category in categoryOrder {
            if let candidate = nextCandidate(in: category, pools: pools) {
                return candidate
            }
        }
        return nil
    }

    private func orderedFallbackCategories(excluding excludedCategory: SuggestionCategory?) -> [SuggestionCategory] {
        let baseOrder: [SuggestionCategory]
        if let lastCategory {
            baseOrder = [lastCategory, .inProgress, .todo, .overdue, .paused]
        } else {
            baseOrder = [.inProgress, .todo, .overdue, .paused]
        }

        var seen = Set<SuggestionCategory>()
        return baseOrder.filter { category in
            guard category != excludedCategory else { return false }
            guard !seen.contains(category) else { return false }
            seen.insert(category)
            return true
        }
    }

    private func normalizeSuggestionMessage(_ message: String, for taskTitle: String) -> String {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTitle = stripWrappingQuotes(from: taskTitle)

        guard !trimmedMessage.isEmpty, !normalizedTitle.isEmpty else {
            return trimmedMessage
        }

        let quotedTitle = "「\(normalizedTitle)」"
        if trimmedMessage.contains(quotedTitle) {
            return trimmedMessage
        }

        return trimmedMessage.replacingOccurrences(of: normalizedTitle, with: quotedTitle)
    }

    private func stripWrappingQuotes(from title: String) -> String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.count >= 2 else { return trimmedTitle }

        let wrappers: [(Character, Character)] = [
            ("「", "」"),
            ("“", "”"),
            ("\"", "\""),
            ("'", "'"),
            ("《", "》"),
        ]

        guard let first = trimmedTitle.first, let last = trimmedTitle.last else {
            return trimmedTitle
        }

        if wrappers.contains(where: { $0.0 == first && $0.1 == last }) {
            return String(trimmedTitle.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return trimmedTitle
    }

    private func weightedCategoryChoice(
        candidates: [(SuggestionCategory?, Int)]
    ) -> SuggestionCategory? {
        let available = candidates.compactMap { category, weight -> (SuggestionCategory, Int)? in
            guard let category else { return nil }
            return (category, weight)
        }

        let totalWeight = available.reduce(0) { $0 + $1.1 }
        guard totalWeight > 0 else { return nil }

        var draw = Int.random(in: 0 ..< totalWeight)
        for (category, weight) in available {
            if draw < weight {
                return category
            }
            draw -= weight
        }

        return available.last?.0
    }

    private func compareInProgressPriority(_ lhs: TaskItem, _ rhs: TaskItem) -> Bool {
        if lhs.progress == rhs.progress {
            return lhs.updatedAt > rhs.updatedAt
        }

        return lhs.progress > rhs.progress
    }

    private func compareOverduePriority(_ lhs: TaskItem, _ rhs: TaskItem) -> Bool {
        let lhsDate = lhs.dueDate ?? .distantFuture
        let rhsDate = rhs.dueDate ?? .distantFuture
        if lhsDate == rhsDate {
            return lhs.updatedAt > rhs.updatedAt
        }
        return lhsDate < rhsDate
    }

    private func compareShortTitlePriority(_ lhs: TaskItem, _ rhs: TaskItem) -> Bool {
        let lhsTitle = lhs.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let rhsTitle = rhs.title.trimmingCharacters(in: .whitespacesAndNewlines)

        if lhsTitle.count == rhsTitle.count {
            return lhs.updatedAt > rhs.updatedAt
        }

        return lhsTitle.count < rhsTitle.count
    }

    private func decodeServerError(from data: Data) throws -> SplitTaskAPIError {
        let apiErrorResponse: SuggestNextActionAPIErrorResponse? =
            try? decoder.decode(SuggestNextActionAPIErrorResponse.self, from: data)

        if let message = apiErrorResponse?.detail,
           !message.isEmpty {
            return .serverMessage(message)
        }

        return .serverMessage("这次整理没有成功，再试一次就好。")
    }
}
