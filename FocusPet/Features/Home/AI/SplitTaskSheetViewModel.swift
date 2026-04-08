import Combine
import Foundation

@MainActor
final class SplitTaskSheetViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published var input: String = ""
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var suggestions: [SplitTaskSuggestion] = []
    @Published private(set) var understandingMessage: String?

    private let provider: any SplitTaskProviding

    init(provider: any SplitTaskProviding = APISplitTaskProvider()) {
        self.provider = provider
    }

    var canSubmit: Bool {
        !normalizedInput.isEmpty && phase != .loading
    }

    var selectedSuggestions: [SplitTaskSuggestion] {
        suggestions.filter(\.isSelected)
    }

    // Keeps the async provider call and UI state transitions in one simple place.
    func generateSuggestions() async {
        let request = normalizedInput
        guard !request.isEmpty else { return }

        phase = .loading

        do {
            let generatedTitles = try await provider.generateSubtasks(from: request)
            suggestions = generatedTitles.map { SplitTaskSuggestion(title: $0) }
            understandingMessage = buildUnderstandingMessage(for: request)
            phase = .loaded
        } catch {
            phase = .failed(errorMessage(for: error))
        }
    }

    func toggleSelection(for suggestionID: UUID) {
        guard let index = suggestions.firstIndex(where: { $0.id == suggestionID }) else { return }
        suggestions[index].isSelected.toggle()
    }

    func resetAfterImport() {
        input = ""
        suggestions = []
        understandingMessage = nil
        phase = .idle
    }

    private var normalizedInput: String {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func errorMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }

        return "这次整理有点卡住了，再试一次就好。"
    }

    private func buildUnderstandingMessage(for input: String) -> String {
        if input.contains("面试") {
            return "我理解你是想准备一次面试，这种目标通常可以慢慢拆成几步推进。"
        }

        if input.contains("作品集") {
            return "我理解你是想整理一份作品集，这类事情先理顺结构会更容易开始。"
        }

        if input.contains("考试") || input.contains("复习") {
            return "我理解你是想把复习慢慢推进，这种目标先拆成几小段会安心很多。"
        }

        return "我理解你想先把这个目标理清一点，这类事情通常拆小以后会更容易推进。"
    }
}
