import Foundation

protocol SplitTaskProviding: Sendable {
    func generateSubtasks(from input: String) async throws -> [String]
}

struct MockSplitTaskProvider: SplitTaskProviding {
    nonisolated init() {}

    nonisolated func generateSubtasks(from input: String) async throws -> [String] {
        try await _Concurrency.Task.sleep(nanoseconds: 1_100_000_000)

        let normalizedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedInput.isEmpty else { return [] }

        if shouldFail(for: normalizedInput) {
            throw SplitTaskError.generationFailed
        }

        return suggestionTemplate(for: normalizedInput)
    }

    private func shouldFail(for input: String) -> Bool {
        let lowercaseInput = input.lowercased()
        return lowercaseInput.contains("error") || input.contains("失败")
    }

    private func suggestionTemplate(for input: String) -> [String] {
        if input.contains("面试") {
            return [
                "先列出这次面试最重要的岗位要求",
                "整理 2 到 3 个能代表你的项目故事",
                "写一个 1 分钟左右的自我介绍",
                "挑 5 个常见问题做一轮简短练习"
            ]
        }

        if input.contains("作品集") {
            return [
                "先确认这次作品集要放哪些项目",
                "给每个项目补一段背景和目标",
                "整理过程图和最终结果图",
                "统一一版排版和封面风格"
            ]
        }

        if input.contains("考试") || input.contains("复习") {
            return [
                "先圈出这次最需要补的章节",
                "把重点概念整理成一页提纲",
                "挑 2 到 3 组题目做一轮练习",
                "把做错的地方单独记下来再看一遍"
            ]
        }

        return [
            "先把这件事要达到的结果写清楚",
            "把需要准备的资料或材料列出来",
            "先完成最容易开始的第一小步",
            "留一点时间检查还有没有漏掉的部分"
        ]
    }
}
