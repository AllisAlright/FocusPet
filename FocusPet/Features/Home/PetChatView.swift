import SwiftUI

private struct PetChatSplitSuggestion: Identifiable, Equatable {
    let id: UUID
    let title: String
    var isSelected: Bool

    init(id: UUID = UUID(), title: String, isSelected: Bool = true) {
        self.id = id
        self.title = title
        self.isSelected = isSelected
    }
}

private enum PetChatAction {
    case runSplitTask(String)
    case splitTaskResult(input: String, suggestions: [PetChatSplitSuggestion], isImported: Bool)
    case openFocus(taskID: UUID?, suggestedMinutes: Int?)
}

private struct PetChatMessage: Identifiable {
    let id: UUID
    let sender: PetChatMessageSender
    let text: String
    var action: PetChatAction?

    init(id: UUID = UUID(), sender: PetChatMessageSender, text: String, action: PetChatAction? = nil) {
        self.id = id
        self.sender = sender
        self.text = text
        self.action = action
    }

    init(storedMessage: PetChatStoredMessage) {
        self.id = storedMessage.id
        self.sender = storedMessage.sender
        self.text = storedMessage.text
        self.action = nil
    }
}

struct PetChatView: View {
    @EnvironmentObject private var store: FocusPetStore
    @Environment(\.dismiss) private var dismiss
    let onOpenFocus: (UUID?, Int?) -> Void
    @State private var messages: [PetChatMessage] = []
    @State private var inputText = ""
    @State private var isSending = false
    @State private var conversationTurnCount = 0
    @State private var toastMessage: String?
    @FocusState private var isInputFocused: Bool

    private let petAgentProvider: any PetAgentProviding = APIPetAgentProvider()

    init(onOpenFocus: @escaping (UUID?, Int?) -> Void = { _, _ in }) {
        self.onOpenFocus = onOpenFocus
    }

    var body: some View {
        VStack(spacing: 0) {
            chatHeader

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(messages) { message in
                            PetChatMessageRow(
                                message: message,
                                petType: store.settings.defaultPet,
                                onToggleSplitSuggestion: toggleSplitSuggestion,
                                onAction: handleMessageAction
                            )
                            .id(message.id)
                        }

                        if isSending {
                            PetTypingRow(petType: store.settings.defaultPet)
                                .id("typing")
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: isSending) { _, _ in
                    scrollToBottom(proxy)
                }
            }

            chatComposer
        }
        .background(chatBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            seedGreetingIfNeeded()
        }
        .overlay(alignment: .top) {
            if let toastMessage {
                SoftFeedbackToast(title: toastMessage)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onChange(of: store.settings.defaultPet) { _, _ in
            loadStoredMessages()
        }
    }

    private var chatHeader: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(FocusPetTheme.Palette.ink)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.48), in: Circle())
            }
            .buttonStyle(.plain)

            PetAvatarBadge(petType: store.settings.defaultPet, size: .small)

            VStack(alignment: .leading, spacing: 3) {
                Text(store.settings.defaultPet.displayName)
                    .font(FocusPetTheme.Typography.headline)
                    .foregroundStyle(FocusPetTheme.Palette.ink)

                Text(chatStatusText)
                    .font(FocusPetTheme.Typography.caption)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(Color.white.opacity(0.20))
    }

    private var chatComposer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                focusPromptButton
                quickPromptButton("帮我拆任务")
                quickPromptButton("我先做哪个")
                quickPromptButton("复盘最近")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .bottom, spacing: 10) {
                TextField("和\(store.settings.defaultPet.displayName)说点什么...", text: $inputText, axis: .vertical)
                    .font(FocusPetTheme.Typography.body)
                    .foregroundStyle(FocusPetTheme.Palette.ink)
                    .textFieldStyle(.plain)
                    .lineLimit(1 ... 4)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit(sendCurrentMessage)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.72), lineWidth: 1)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .onTapGesture {
                        isInputFocused = true
                    }

                Button(action: sendCurrentMessage) {
                    ZStack {
                        Circle()
                            .fill(canSend ? FocusPetTheme.Palette.sage.opacity(0.88) : Color.white.opacity(0.60))
                            .frame(width: 42, height: 42)

                        if isSending {
                            ProgressView()
                                .controlSize(.small)
                                .tint(FocusPetTheme.Palette.ink)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(FocusPetTheme.Palette.ink)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(!canSend || isSending)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isInputFocused = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var chatBackground: some View {
        LinearGradient(
            colors: [
                FocusPetTheme.Palette.mist,
                FocusPetTheme.Palette.rain.opacity(0.95),
                FocusPetTheme.Palette.warm.opacity(0.84)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var chatStatusText: String {
        if todayFocusMinutes > 0 {
            return "今天陪你专注了 \(todayFocusMinutes) 分钟"
        }
        return "在这里陪你慢慢说"
    }

    private var todayFocusMinutes: Int {
        store.focusSessions
            .filter { Calendar.current.isDateInToday($0.startedAt) }
            .map(\.durationMinutes)
            .reduce(0, +)
    }

    private func quickPromptButton(_ title: String) -> some View {
        Button {
            inputText = title
            isInputFocused = true
        } label: {
            Text(title)
                .font(FocusPetTheme.Typography.caption)
                .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                .lineLimit(1)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.52), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var focusPromptButton: some View {
        Button {
            isInputFocused = false
            onOpenFocus(nil, nil)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 11, weight: .semibold))

                Text("去专注")
                    .lineLimit(1)
            }
            .font(FocusPetTheme.Typography.caption)
            .foregroundStyle(FocusPetTheme.Palette.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(FocusPetTheme.Palette.sage.opacity(0.62), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func seedGreetingIfNeeded() {
        loadStoredMessages()
        guard messages.isEmpty else { return }
        appendMessage(sender: .pet, text: greetingText)
    }

    private var greetingText: String {
        switch store.settings.defaultPet {
        case .rabbit:
            return "我在这里。你可以先说说现在卡在哪里。"
        case .cat:
            return "说吧，我听着。我们先把事情理清楚。"
        case .dog:
            return "我来啦！想聊聊，还是想先找个小起点？"
        case .hamster:
            return "哼，我刚好有空。说吧，哪里卡住了？"
        }
    }

    private func sendCurrentMessage() {
        let input = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, !isSending else { return }

        inputText = ""
        appendMessage(sender: .user, text: input)
        conversationTurnCount += 1

        isSending = true
        let petType = store.settings.defaultPet
        let tasks = store.tasks
        let focusSessions = store.focusSessions
        let turnCount = conversationTurnCount

        _Concurrency.Task {
            do {
                let response = try await petAgentProvider.sendMessage(
                    input,
                    petType: petType,
                    conversationTurnCount: turnCount,
                    tasks: tasks,
                    focusSessions: focusSessions
                )

                await MainActor.run {
                    isSending = false
                    appendAgentResponse(response, originalInput: input)
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    appendLocalReply(for: input)
                }
            }
        }
    }

    private func appendAgentResponse(_ response: PetAgentResponse, originalInput: String) {
        let safeReply = response.message.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalText = safeReply.isEmpty ? casualReply(for: originalInput) : safeReply
        let action = action(for: response, originalInput: originalInput)
        let messageParts = splitPetReply(finalText)

        for (index, messagePart) in messageParts.enumerated() {
            let partAction = index == messageParts.count - 1 ? action : nil
            appendMessage(sender: .pet, text: messagePart, action: partAction)
        }
    }

    private func action(for response: PetAgentResponse, originalInput: String) -> PetChatAction? {
        guard response.safetyLevel == "safe" else { return nil }

        if response.skill == "suggest_next_action",
           let recommendation = response.recommendation {
            return .openFocus(
                taskID: recommendationTaskID(recommendation),
                suggestedMinutes: recommendation.suggestedFocusMinutes
            )
        }

        guard response.skill == "split_task" else { return nil }

        let input = cleanedSplitTaskInput(from: originalInput)
        let suggestions = makeInlineSplitSuggestions(from: response.tasks)
        guard !suggestions.isEmpty else {
            return .runSplitTask(input)
        }

        return .splitTaskResult(input: input, suggestions: suggestions, isImported: false)
    }

    private func appendLocalReply(for input: String) {
        let action: PetChatAction?
        let text: String

        switch classifyAgentInput(input) {
        case .selfHarm:
            action = nil
            text = localSelfHarmResponse
        case .unsafe:
            action = nil
            text = localUnsafeResponse
        case .oversizedGoal:
            action = nil
            text = localOversizedGoalResponse
        case .relationshipEmotional:
            action = nil
            text = localRelationshipEmotionalResponse
        case .splitTask:
            action = .splitTaskResult(
                input: cleanedSplitTaskInput(from: input),
                suggestions: makeInlineSplitSuggestions(from: localSplitTaskTitles(for: input)),
                isImported: false
            )
            text = splitTaskInlinePrompt
        case .nextAction:
            let recommendation = store.taskRecommendation
            action = recommendation.taskID.map { .openFocus(taskID: $0, suggestedMinutes: 15) }
            text = localNextActionFallback()
        case .weeklyReview:
            action = nil
            text = weeklyReviewMessage()
        case .casual:
            action = nil
            text = casualReply(for: input)
        }

        appendPetReply(text, action: action)
    }

    private func handleMessageAction(messageID: UUID, action: PetChatAction) {
        switch action {
        case let .runSplitTask(input):
            requestInlineSplitTask(for: input)
        case let .splitTaskResult(_, suggestions, isImported):
            guard !isImported else { return }
            let selectedTitles = suggestions
                .filter(\.isSelected)
                .map(\.title)
            guard !selectedTitles.isEmpty else { return }

            importGeneratedTasks(selectedTitles)
            markSplitTaskImported(messageID: messageID)
            appendMessage(sender: .pet, text: splitTaskImportedReply(count: selectedTitles.count))
        case let .openFocus(taskID, suggestedMinutes):
            isInputFocused = false
            onOpenFocus(taskID, suggestedMinutes)
        }
    }

    private func toggleSplitSuggestion(messageID: UUID, suggestionID: UUID) {
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageID }) else { return }
        guard case let .splitTaskResult(input, suggestions, isImported) = messages[messageIndex].action,
              !isImported,
              let suggestionIndex = suggestions.firstIndex(where: { $0.id == suggestionID }) else { return }

        var updatedSuggestions = suggestions
        updatedSuggestions[suggestionIndex].isSelected.toggle()
        messages[messageIndex].action = .splitTaskResult(
            input: input,
            suggestions: updatedSuggestions,
            isImported: false
        )
    }

    private func markSplitTaskImported(messageID: UUID) {
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageID }) else { return }
        guard case let .splitTaskResult(input, suggestions, _) = messages[messageIndex].action else { return }

        messages[messageIndex].action = .splitTaskResult(
            input: input,
            suggestions: suggestions,
            isImported: true
        )
    }

    private func requestInlineSplitTask(for input: String) {
        let normalizedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedInput.isEmpty, !isSending else { return }

        isSending = true
        let petType = store.settings.defaultPet
        let tasks = store.tasks
        let focusSessions = store.focusSessions
        let turnCount = conversationTurnCount
        let requestInput = "帮我拆一下\(normalizedInput)"

        _Concurrency.Task {
            do {
                let response = try await petAgentProvider.sendMessage(
                    requestInput,
                    petType: petType,
                    conversationTurnCount: turnCount,
                    tasks: tasks,
                    focusSessions: focusSessions
                )

                await MainActor.run {
                    isSending = false
                    appendAgentResponse(response, originalInput: normalizedInput)
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    appendLocalSplitTaskReply(for: normalizedInput)
                }
            }
        }
    }

    private func appendLocalSplitTaskReply(for input: String) {
        appendPetReply(
            splitTaskInlinePrompt,
            action: .splitTaskResult(
                input: input,
                suggestions: makeInlineSplitSuggestions(from: localSplitTaskTitles(for: input)),
                isImported: false
            )
        )
    }

    private func loadStoredMessages() {
        messages = store.chatMessages(for: store.settings.defaultPet)
            .map(PetChatMessage.init(storedMessage:))
        conversationTurnCount = messages.filter { $0.sender == .user }.count
    }

    private func appendMessage(
        sender: PetChatMessageSender,
        text: String,
        action: PetChatAction? = nil
    ) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let storedMessage = store.appendPetChatMessage(
            petType: store.settings.defaultPet,
            sender: sender,
            text: trimmedText
        )
        messages.append(PetChatMessage(id: storedMessage.id, sender: sender, text: trimmedText, action: action))
    }

    private func appendPetReply(_ text: String, action: PetChatAction? = nil) {
        let messageParts = splitPetReply(text)
        for (index, messagePart) in messageParts.enumerated() {
            appendMessage(sender: .pet, text: messagePart, action: index == messageParts.count - 1 ? action : nil)
        }
    }

    private func splitPetReply(_ text: String) -> [String] {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return [] }

        let normalizedText = trimmedText
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n", with: " ")
        let sentenceTerminators = CharacterSet(charactersIn: "。！？!?")
        var sentences: [String] = []
        var current = ""

        for character in normalizedText {
            current.append(character)
            if String(character).rangeOfCharacter(from: sentenceTerminators) != nil {
                let sentence = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentence.isEmpty {
                    sentences.append(sentence)
                }
                current = ""
            }
        }

        let remainder = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !remainder.isEmpty {
            sentences.append(remainder)
        }

        guard sentences.count > 1 else { return [trimmedText] }

        var groupedMessages: [String] = []
        var currentGroup: [String] = []
        for sentence in sentences {
            currentGroup.append(sentence)
            if currentGroup.count == 2 {
                groupedMessages.append(currentGroup.joined(separator: " "))
                currentGroup = []
            }
        }

        if !currentGroup.isEmpty {
            groupedMessages.append(currentGroup.joined(separator: " "))
        }

        return groupedMessages
    }

    private func importGeneratedTasks(_ titles: [String]) {
        for title in titles {
            _ = store.createTask(
                title: title,
                enableFocus: true,
                preferredPet: store.settings.defaultPet
            )
        }

        showToast(titles.count == 1 ? "已加进待办里了。" : "已添加 \(titles.count) 个待办事项")
    }

    private func recommendationTaskID(_ recommendation: PetAgentNextActionRecommendation) -> UUID? {
        guard let taskID = recommendation.taskID else { return nil }
        return UUID(uuidString: taskID)
    }

    private func makeInlineSplitSuggestions(from titles: [String]) -> [PetChatSplitSuggestion] {
        titles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { PetChatSplitSuggestion(title: $0) }
    }

    private var splitTaskInlinePrompt: String {
        switch store.settings.defaultPet {
        case .rabbit:
            return "我帮你拆成几小步了，先选想放进待办里的就好。"
        case .cat:
            return "拆好了。先挑真正需要进入待办的几步。"
        case .dog:
            return "拆好啦！选几步放进待办，我们一点点动起来。"
        case .hamster:
            return "哼，拆好了。先选要放进待办的，别一口气塞太多。"
        }
    }

    private func splitTaskImportedReply(count: Int) -> String {
        switch store.settings.defaultPet {
        case .rabbit:
            return count == 1 ? "放好啦，我们之后可以慢慢推进这一小步。" : "放好啦，这几步之后可以慢慢推进。"
        case .cat:
            return count == 1 ? "放好了。先从这一小步开始。" : "放好了。待办里会清楚一些。"
        case .dog:
            return count == 1 ? "放好啦！我们可以从这一小步开始。" : "放好啦！这些小步会更容易开始。"
        case .hamster:
            return count == 1 ? "放好了，哼，就先盯这一小步。" : "放好了，几小格够你慢慢滚了。"
        }
    }

    private func localSplitTaskTitles(for input: String) -> [String] {
        if input.contains("面试") {
            return [
                "列出这次面试最重要的岗位要求。",
                "整理 2 到 3 个能代表你的项目经历。",
                "写一个 1 分钟左右的自我介绍。",
                "挑 5 个常见问题做一轮简短练习。"
            ]
        }

        if input.contains("作品集") {
            return [
                "确认这次作品集要放进哪些项目。",
                "给每个项目补一段背景、目标和结果。",
                "整理项目过程图和最终展示图。",
                "统一一版排版、封面和导出格式。"
            ]
        }

        if input.contains("考试") || input.contains("复习") {
            return [
                "圈出这次最需要补的章节。",
                "把重点概念整理成一页提纲。",
                "挑 2 到 3 组题目做一轮练习。",
                "把做错的地方单独记下来再看一遍。"
            ]
        }

        return [
            "先写下这件事想达到的结果。",
            "列出需要准备的资料或材料。",
            "完成最容易开始的第一小步。",
            "留一点时间检查还有没有漏掉的内容。"
        ]
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
            toastMessage = message
        }

        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: 1_500_000_000)
            guard toastMessage == message else { return }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.22)) {
                    toastMessage = nil
                }
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.22)) {
                if isSending {
                    proxy.scrollTo("typing", anchor: .bottom)
                } else if let lastID = messages.last?.id {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
    }

    private enum AgentInputKind: Equatable {
        case selfHarm
        case unsafe
        case oversizedGoal
        case relationshipEmotional
        case splitTask
        case nextAction
        case weeklyReview
        case casual
    }

    private func classifyAgentInput(_ input: String) -> AgentInputKind {
        let normalized = input.localizedLowercase

        if containsAny(normalized, keywords: ["自杀", "轻生", "不想活", "结束生命", "伤害自己", "死掉"]) {
            return .selfHarm
        }

        if containsAny(normalized, keywords: ["吃屎", "违法", "打人", "杀人", "放火", "翻墙", "黄片", "a片", "色情", "约炮"]) {
            return .unsafe
        }

        if containsAny(normalized, keywords: ["一百万", "100万", "百万", "财富自由", "暴富", "人生规划", "当总统", "做总统", "成为总统"]) {
            return .oversizedGoal
        }

        if containsAny(normalized, keywords: ["喜欢一个人", "喜欢上一个人", "喜欢上了一个人", "让他喜欢我", "让她喜欢我", "让对方喜欢我", "追到", "表白", "脱单", "挽回"]) {
            return .relationshipEmotional
        }

        if containsAny(normalized, keywords: ["复盘", "总结最近", "最近状态", "这周怎么样", "这一周怎么样"]) {
            return .weeklyReview
        }

        if containsAny(normalized, keywords: ["先做哪个", "下一步", "不知道先", "从哪开始", "先干什么", "先做什么"]) {
            return .nextAction
        }

        if containsAny(normalized, keywords: ["拆", "拆解", "分成几步", "怎么准备", "怎么做", "不知道怎么"]) {
            return .splitTask
        }

        return .casual
    }

    private func containsAny(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }

    private var localSelfHarmResponse: String {
        switch store.settings.defaultPet {
        case .rabbit:
            return "我不能帮你规划伤害自己的事。先别一个人待着，找身边可信的人陪你，好吗？"
        case .cat:
            return "这个不能帮你拆。先别一个人待着，联系可信的人或当地紧急帮助。"
        case .dog:
            return "我不能帮你伤害自己。先找一个可信的人陪你，现在安全最重要。"
        case .hamster:
            return "这个不行。先把危险的东西放远，找个可信的人过来，我会在这里等你。"
        }
    }

    private var localUnsafeResponse: String {
        switch store.settings.defaultPet {
        case .rabbit:
            return "这件事不适合放进待办推进。我们先停一下，回到眼前能照顾好的那一步。"
        case .cat:
            return "这个话题不适合继续。换一个学习、工作或生活里的具体任务。"
        case .dog:
            return "这个我不能帮忙。我们先回到学习、工作或生活里的一小步吧。"
        case .hamster:
            return "哼，这个不接。换个能放进待办的小任务吧。"
        }
    }

    private var localOversizedGoalResponse: String {
        switch store.settings.defaultPet {
        case .rabbit:
            return "这个目标太大了，直接拆会变得不真实。我们先缩到最近一周能验证的一件事。"
        case .cat:
            return "范围太大了。先缩成最近一周能验证的一个起点。"
        case .dog:
            return "这个目标不能直接拆，不然会太飘。我们先找一个最近能验证的小开头。"
        case .hamster:
            return "这团太大了，直接拆会变成空话。先捏成一周内能试的一小块。"
        }
    }

    private var localRelationshipEmotionalResponse: String {
        switch store.settings.defaultPet {
        case .rabbit:
            return "感情里的事不能拆成保证结果的步骤。我们可以先聊聊你在意的是什么。"
        case .cat:
            return "这不是能保证结果的待办。先分清你想表达什么，也尊重对方的边界。"
        case .dog:
            return "喜欢一个人不是任务通关啦。我们可以先聊聊你的感受，也照顾对方的边界。"
        case .hamster:
            return "哼，这种事不能按步骤保证成功。先说清楚你到底在意哪一点吧。"
        }
    }

    private func cleanedSplitTaskInput(from input: String) -> String {
        var cleaned = input
        let removableFragments = ["帮我", "拆一下", "拆解", "分成几步", "我不知道怎么", "怎么准备", "怎么做"]
        for fragment in removableFragments {
            cleaned = cleaned.replacingOccurrences(of: fragment, with: "")
        }
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? input : trimmed
    }

    private func localNextActionFallback() -> String {
        let recommendation = store.taskRecommendation
        switch recommendation.kind {
        case .continueTask:
            return "\(recommendation.message) 它比较适合现在接着做，要不要先来 15 分钟？"
        case .reactivateTask:
            return "\(recommendation.message) 不用一次做完，先捡回一点点就好。"
        case .empty:
            return recommendation.message
        }
    }

    private func weeklyReviewMessage() -> String {
        let calendar = Calendar.current
        let since = calendar.date(byAdding: .day, value: -7, to: Date.now) ?? Date.now
        let recentSessions = store.focusSessions.filter { $0.startedAt >= since && $0.isFinished }
        let totalMinutes = recentSessions.map(\.durationMinutes).reduce(0, +)

        guard !recentSessions.isEmpty else {
            return reviewEmptyMessage
        }

        let lateNightCount = recentSessions.filter {
            let hour = calendar.component(.hour, from: $0.startedAt)
            return hour >= 23 || hour < 5
        }.count
        let topTaskTitle = mostFocusedTaskTitle(from: recentSessions)

        switch store.settings.defaultPet {
        case .rabbit:
            if lateNightCount >= 2 {
                return "这 7 天你专注了 \(recentSessions.count) 次，累计 \(totalMinutes) 分钟。我也看见你有几次很晚还在努力，记得早点休息。"
            }
            return "这 7 天你专注了 \(recentSessions.count) 次，累计 \(totalMinutes) 分钟。好多努力其实都已经留下来了。"
        case .cat:
            if let topTaskTitle {
                return "这 7 天累计 \(totalMinutes) 分钟，主要在推进「\(topTaskTitle)」。进展是看得见的，节奏稳一点更好。"
            }
            return "这 7 天累计 \(totalMinutes) 分钟。记录不算吵，但它说明你确实有在推进。"
        case .dog:
            return "这周有 \(recentSessions.count) 次专注记录，累计 \(totalMinutes) 分钟！你真的有在往前走，慢慢来就很好。"
        case .hamster:
            if lateNightCount >= 2 {
                return "哼，居然攒了 \(totalMinutes) 分钟。你有几次半夜还在学，我都困了，努力归努力，别把电量耗空。"
            }
            return "哼，还不错嘛。这 7 天你专注了 \(recentSessions.count) 次，累计 \(totalMinutes) 分钟，不是完全没动。"
        }
    }

    private var reviewEmptyMessage: String {
        switch store.settings.defaultPet {
        case .rabbit:
            return "最近 7 天还没有专注记录。没关系，我们从下一小段开始也可以。"
        case .cat:
            return "最近 7 天没有专注记录。先记下一件事，会更容易开始。"
        case .dog:
            return "这 7 天还没有专注记录。那我们就从一小轮开始吧！"
        case .hamster:
            return "最近 7 天空空的。哼，那就先攒第一小格吧。"
        }
    }

    private func mostFocusedTaskTitle(from sessions: [FocusSession]) -> String? {
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

        return store.task(with: topTaskID)?.title
    }

    private func casualReply(for input: String) -> String {
        if conversationTurnCount >= 8 {
            return closingChatReply
        }

        if containsAny(input, keywords: ["累", "烦", "不想", "没力气"]) {
            switch store.settings.defaultPet {
            case .rabbit:
                return "那就先歇一小会儿，我陪你安静待着。"
            case .cat:
                return "先停一下也可以。等心稳了，再看一件小事。"
            case .dog:
                return "累了就先缓一缓，我在这里等你。"
            case .hamster:
                return "哼，那就先休息一下，电量太低也跑不动。"
            }
        }

        switch store.settings.defaultPet {
        case .rabbit:
            return "我听见啦。我们可以慢慢把它放清楚。"
        case .cat:
            return "嗯，先把眼前这一点理顺。"
        case .dog:
            return "好呀，我陪你一起看一看！"
        case .hamster:
            return "哼，我听着呢，说不定能帮你找个起点。"
        }
    }

    private var closingChatReply: String {
        switch store.settings.defaultPet {
        case .rabbit:
            return "我还在这里。等你愿意的时候，我们可以休息一下，或者只记下一件小事。"
        case .cat:
            return "聊到这里也够了。接下来可以休息，或者先整理一件最小的事。"
        case .dog:
            return "我还想陪你，但也可以先休息一下，或者来一个 5 分钟小开始！"
        case .hamster:
            return "哼，已经聊不少了。要么休息，要么先写下一件小事，我都行。"
        }
    }

    private func reviewMessage(from response: PetAgentResponse) -> String {
        guard let review = response.review else {
            return response.message
        }

        return [review.summary, review.observation, review.petComment]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

private struct PetChatMessageRow: View {
    let message: PetChatMessage
    let petType: PetType
    let onToggleSplitSuggestion: (UUID, UUID) -> Void
    let onAction: (UUID, PetChatAction) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            if message.sender == .pet {
                PetAvatarBadge(petType: petType, size: .small)
                    .scaleEffect(0.62)
                    .frame(width: 38, height: 38)
                    .padding(.top, 3)
                bubble(alignment: .leading)
                Spacer(minLength: 46)
            } else {
                Spacer(minLength: 54)
                bubble(alignment: .trailing)
            }
        }
    }

    private func bubble(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 8) {
            Text(message.text)
                .font(FocusPetTheme.Typography.body)
                .foregroundStyle(FocusPetTheme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            if let action = message.action {
                actionContent(action)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(bubbleFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(message.sender == .pet ? 0.70 : 0.34), lineWidth: 1)
        )
    }

    private var bubbleFill: Color {
        switch message.sender {
        case .pet:
            return Color.white.opacity(0.76)
        case .user:
            return FocusPetTheme.Palette.sage.opacity(0.82)
        }
    }

    @ViewBuilder
    private func actionContent(_ action: PetChatAction) -> some View {
        switch action {
        case .runSplitTask:
            Button {
                onAction(message.id, action)
            } label: {
                Text("帮我拆成几步")
                    .font(FocusPetTheme.Typography.caption)
                    .foregroundStyle(FocusPetTheme.Palette.ink)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(FocusPetTheme.Palette.sage.opacity(0.70), in: Capsule())
            }
            .buttonStyle(.plain)

        case let .splitTaskResult(input, suggestions, isImported):
            splitTaskResultContent(input: input, suggestions: suggestions, isImported: isImported)

        case let .openFocus(_, suggestedMinutes):
            Button {
                onAction(message.id, action)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "timer")
                        .font(.system(size: 11, weight: .semibold))

                    Text(focusActionTitle(suggestedMinutes: suggestedMinutes))
                }
                .font(FocusPetTheme.Typography.caption)
                .foregroundStyle(FocusPetTheme.Palette.ink)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(FocusPetTheme.Palette.sage.opacity(0.70), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func splitTaskResultContent(
        input: String,
        suggestions: [PetChatSplitSuggestion],
        isImported: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(suggestions) { suggestion in
                    Button {
                        onToggleSplitSuggestion(message.id, suggestion.id)
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: suggestion.isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(suggestion.isSelected ? FocusPetTheme.Palette.sage : FocusPetTheme.Palette.inkSoft)
                                .frame(width: 18, height: 18)
                                .padding(.top, 1)

                            Text(suggestion.title)
                                .font(FocusPetTheme.Typography.caption)
                                .foregroundStyle(FocusPetTheme.Palette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.46), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isImported)
                }
            }

            if isImported {
                Text("已加入待办")
                    .font(FocusPetTheme.Typography.caption)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.48), in: Capsule())
            } else {
                HStack(spacing: 8) {
                    Button {
                        onAction(message.id, .splitTaskResult(input: input, suggestions: suggestions, isImported: false))
                    } label: {
                        Text("加入选中")
                            .font(FocusPetTheme.Typography.caption)
                            .foregroundStyle(FocusPetTheme.Palette.ink)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(
                                FocusPetTheme.Palette.sage.opacity(selectedCount(in: suggestions) == 0 ? 0.32 : 0.70),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedCount(in: suggestions) == 0)

                    Button {
                        onAction(message.id, .runSplitTask(input))
                    } label: {
                        Text("重新拆一下")
                            .font(FocusPetTheme.Typography.caption)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.48), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func selectedCount(in suggestions: [PetChatSplitSuggestion]) -> Int {
        suggestions.filter(\.isSelected).count
    }

    private func focusActionTitle(suggestedMinutes: Int?) -> String {
        guard let suggestedMinutes else {
            return "去专注"
        }
        return "去专注 \(suggestedMinutes) 分钟"
    }
}

private struct PetTypingRow: View {
    let petType: PetType

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            PetAvatarBadge(petType: petType, size: .small)
                .scaleEffect(0.62)
                .frame(width: 38, height: 38)
                .padding(.top, 3)

            HStack(spacing: 7) {
                ProgressView()
                    .controlSize(.small)
                    .tint(FocusPetTheme.Palette.inkSoft)

                Text("正在想...")
                    .font(FocusPetTheme.Typography.body)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Spacer(minLength: 46)
        }
    }
}
