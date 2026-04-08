import SwiftUI

private enum HomeSceneRoute: Hashable {
    case memo
    case tasks
    case focus
    case history
}

private enum HomeBubbleState {
    case emotion
    case loading
    case suggestion
}

struct HomeSceneView: View {
    @EnvironmentObject private var store: FocusPetStore
    @State private var path: [HomeSceneRoute] = []
    @State private var showPetSheet = false
    @State private var showSplitTaskSheet = false
    @State private var splitTaskSuccessMessage: String?
    @State private var petMood: PetMood = .neutral
    @State private var cachedSuggestion: String?
    @State private var lastRefreshTimestamps: [Date] = []
    @State private var isRefreshingSuggestion = false
    @State private var bubbleState: HomeBubbleState = .emotion

    private let suggestNextActionProvider: any SuggestNextActionProviding = APISuggestNextActionProvider()

    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top
            let compact = proxy.size.width < 390

            NavigationStack(path: $path) {
                ZStack {
                    backgroundLayer

                    roomScene(compact: compact)
                        .padding(.horizontal, FocusPetTheme.Spacing.large)
                        .padding(.top, min(max(topInset, 0), 8))
                        .padding(.bottom, 4)
                        .frame(maxWidth: .infinity, alignment: .top)

                    if let splitTaskSuccessMessage {
                        SoftFeedbackToast(title: splitTaskSuccessMessage)
                            .padding(.horizontal, FocusPetTheme.Spacing.large)
                            .padding(.bottom, compact ? 112 : 122)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: HomeSceneRoute.self) { route in
                    destinationView(for: route)
                }
                .onAppear {
                    store.registerHomeOpened()
                    bubbleState = .emotion
                }
                .onDisappear {
                    bubbleState = .emotion
                }
                .onChange(of: store.agentEvents.first?.id) { _, _ in
                    guard let latestEvent = store.agentEvents.first else { return }
                    guard latestEvent.type == .taskCreated || latestEvent.type == .taskCompleted else { return }

                    cachedSuggestion = nil
                }
                .sheet(isPresented: $showPetSheet) {
                    HomePetSelectionSheet(
                        selectedPet: store.settings.defaultPet,
                        onSelect: { pet in
                            store.updateDefaultPet(pet)
                            showPetSheet = false
                        }
                    )
                    .presentationDetents([.height(272)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                }
                .sheet(isPresented: $showSplitTaskSheet) {
                    SplitTaskSheetView(preferredPet: store.settings.defaultPet) { selectedTitles in
                        importGeneratedTasks(selectedTitles)
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(30)
                }
            }
        }
    }

    private func roomScene(compact: Bool) -> some View {
        GeometryReader { proxy in
            let topCardsTop = compact ? 28.0 : 32.0
            let petCenterY = proxy.size.height * (compact ? 0.54 : 0.55)
            let petSectionTop = petCenterY - (compact ? 74 : 86)
            let petFrameHeight = compact ? 136.0 : 154.0
            let assistantTop = petSectionTop + petFrameHeight + (compact ? 28.0 : 32.0)
            let bottomCardsBottom = compact ? 12.0 : 16.0

            ZStack {
                VStack(spacing: compact ? 12 : 16) {
                    HStack(spacing: FocusPetTheme.Spacing.medium) {
                        SceneObjectButton(
                            title: "备忘录",
                            subtitle: "",
                            style: .notebook,
                            action: { path.append(.memo) }
                        )

                        SceneObjectButton(
                            title: "历史事项",
                            subtitle: "",
                            style: .archiveBox,
                            action: { path.append(.history) }
                        )
                    }
                    .padding(.horizontal, compact ? 14 : 16)

                    dialogueCard(compact: compact)
                        .padding(.horizontal, compact ? 18 : 20)
                }
                .padding(.top, topCardsTop)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                ZStack {
                    floorShadow
                        .offset(y: 80)

                    PetCharacterView(petType: store.settings.defaultPet, mood: petMood)
                        .scaleEffect(compact ? 0.74 : 0.82)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.72)) {
                                petMood = reactionMood(for: store.settings.defaultPet)
                            }
                            _Concurrency.Task {
                                try? await _Concurrency.Task.sleep(nanoseconds: 1_000_000_000)
                                await MainActor.run {
                                    withAnimation(.easeInOut(duration: 0.26)) {
                                        petMood = .neutral
                                    }
                                }
                            }
                        }

                    Button {
                        showPetSheet = true
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: compact ? 13 : 14, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.76))
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                    .offset(x: compact ? 68 : 74, y: compact ? 72 : 80)
                    .zIndex(1)
                }
                .frame(height: petFrameHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .offset(y: petSectionTop)

                assistantActionCard(compact: compact)
                    .padding(.top, assistantTop)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                HStack(spacing: FocusPetTheme.Spacing.medium) {
                    SceneObjectButton(
                        title: "待办事项",
                        subtitle: "",
                        style: .board,
                        action: { path.append(.tasks) }
                    )

                    SceneObjectButton(
                        title: "专注",
                        subtitle: "",
                        style: .lampClock,
                        action: { path.append(.focus) }
                    )
                }
                .padding(.horizontal, compact ? 14 : 16)
                .padding(.bottom, bottomCardsBottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
    }

    private func assistantActionCard(compact: Bool) -> some View {
        Button {
            showSplitTaskSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.52))
                        .frame(width: compact ? 34 : 38, height: compact ? 34 : 38)

                    Image(systemName: "sparkles")
                        .font(.system(size: compact ? 13 : 14, weight: .semibold))
                        .foregroundStyle(FocusPetTheme.Palette.ink)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("帮我拆一个任务")
                        .font(FocusPetTheme.Typography.headline)
                        .foregroundStyle(FocusPetTheme.Palette.ink)

                    Text("分成几步，会更容易开始~")
                        .font(FocusPetTheme.Typography.subheadline)
                        .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft.opacity(0.88))
            }
            .padding(.horizontal, compact ? 16 : 18)
            .padding(.vertical, compact ? 8 : 10)
            .background(
                RoundedRectangle(cornerRadius: FocusPetTheme.Radius.medium, style: .continuous)
                    .fill(Color.white.opacity(0.30))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FocusPetTheme.Radius.medium, style: .continuous)
                    .stroke(Color.white.opacity(0.34), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: compact ? 288 : 320)
    }

    private func dialogueCard(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            bubbleContent

            Spacer(minLength: compact ? 6 : 8)

            if let actionTitle = bubbleActionTitle {
                HStack {
                    Spacer(minLength: 0)

                    Button(actionTitle) {
                        handleBubbleAction()
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft.opacity(0.78))
                    .buttonStyle(.plain)
                    .disabled(isRefreshingSuggestion)
                    .opacity(isRefreshingSuggestion ? 0.56 : 1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: compact ? 80 : 84, alignment: .topLeading)
        .padding(.horizontal, 24)
        .padding(.vertical, compact ? 18 : 20)
        .background(Color.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .bottom) {
            HomeDialogueTail()
                .fill(Color.white.opacity(0.42))
                .frame(width: compact ? 20 : 22, height: compact ? 12 : 14)
                .offset(x: compact ? 8 : 12, y: compact ? 8 : 9)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.32), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, y: 8)
    }

    private var floorShadow: some View {
        Ellipse()
            .fill(Color.black.opacity(0.10))
            .frame(width: 176, height: 30)
            .blur(radius: 12)
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    FocusPetTheme.Palette.mist,
                    FocusPetTheme.Palette.rain.opacity(0.92),
                    FocusPetTheme.Palette.warm.opacity(0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 36)
                .offset(x: -160, y: -340)

            Circle()
                .fill(FocusPetTheme.Palette.warm.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 34)
                .offset(x: 180, y: 300)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.04),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func destinationView(for route: HomeSceneRoute) -> some View {
        switch route {
        case .memo:
            MemoPlaceholderView()
        case .tasks:
            TasksPlaceholderView()
        case .focus:
            FocusSetupView()
        case .history:
            HistoryPlaceholderView()
        }
    }

    private var companionMessage: String {
        switch store.settings.defaultPet {
        case .rabbit:
            return "没关系，我们静下心就好。要不要选一个计划开始？"
        case .cat:
            return "放心，我会陪你一起慢慢推进。今天想先从哪件事开始？"
        case .dog:
            return "冲呀！我们今天也一起加油～先从哪个任务开始呢？"
        case .hamster:
            return "别着急，进度是日积月累的结果。今天想推进哪个计划呢？"
        }
    }

    private var companionDetail: String {
        switch store.settings.defaultPet {
        case .rabbit:
            return "外面的雨慢慢下，我们就在这里安静推进一点点。"
        case .cat:
            return "不用着急，我们先把注意力放到眼前这一项任务。"
        case .dog:
            return "我会一直陪着你完成一项又一项任务。"
        case .hamster:
            return "你专注投入的每分每秒，我都知道。"
        }
    }

    @ViewBuilder
    private var bubbleContent: some View {
        ZStack(alignment: .topLeading) {
            switch bubbleState {
            case .emotion:
                Text(companionMessage)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(FocusPetTheme.Palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .offset(y: 2)))
                    .id("emotion")

            case .loading:
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(FocusPetTheme.Palette.inkSoft)

                    Text("让我想一想...")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(FocusPetTheme.Palette.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .transition(.opacity)
                .id("loading")

            case .suggestion:
                Text(cachedSuggestion ?? companionDetail)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(FocusPetTheme.Palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .offset(y: 3)))
                    .id(cachedSuggestion ?? "suggestion")
            }
        }
        .animation(.easeInOut(duration: 0.2), value: bubbleState)
        .animation(.easeInOut(duration: 0.2), value: cachedSuggestion)
    }

    private var bubbleActionTitle: String? {
        switch bubbleState {
        case .emotion:
            return "给个建议"
        case .loading:
            return nil
        case .suggestion:
            return "换一个建议"
        }
    }

    private func handleBubbleAction() {
        switch bubbleState {
        case .emotion:
            requestSuggestionIfNeeded()
        case .loading:
            break
        case .suggestion:
            refreshSuggestionManually()
        }
    }

    private func reactionMood(for petType: PetType) -> PetMood {
        switch petType {
        case .rabbit:
            return .cute
        case .cat:
            return .happy
        case .dog:
            return .happy
        case .hamster:
            return .cute
        }
    }

    private func importGeneratedTasks(_ titles: [String]) {
        for title in titles {
            _ = store.createTask(
                title: title,
                enableFocus: true,
                preferredPet: store.settings.defaultPet
            )
        }

        let message = titles.count == 1 ? "已加进待办里了。" : "已添加 \(titles.count) 个待办事项"
        showSuccessToast(message)
    }

    private func requestSuggestionIfNeeded() {
        bubbleState = .loading

        guard cachedSuggestion == nil else {
            withAnimation(.easeInOut(duration: 0.18)) {
                bubbleState = .suggestion
            }
            return
        }

        fetchActionSuggestion(isManualRefresh: false)
    }

    private func refreshSuggestionManually() {
        bubbleState = .loading
        let now = Date()

        // Only count refresh taps in a short recent window.
        // If the user pauses for a while, older taps fall out naturally.
        lastRefreshTimestamps = lastRefreshTimestamps.filter {
            now.timeIntervalSince($0) < 20
        }
        lastRefreshTimestamps.append(now)

        if lastRefreshTimestamps.count >= 5 {
            cachedSuggestion = fallbackSuggestion(for: lastRefreshTimestamps.count)
            withAnimation(.easeInOut(duration: 0.18)) {
                bubbleState = .suggestion
            }
            return
        }

        fetchActionSuggestion(isManualRefresh: true)
    }

    private func fetchActionSuggestion(isManualRefresh: Bool) {
        let tasks = store.tasks
        isRefreshingSuggestion = true

        _Concurrency.Task {
            do {
                let suggestion = try await suggestNextActionProvider.suggestNextAction(
                    from: tasks,
                    isManualRefresh: isManualRefresh
                )
                let softenedSuggestion = softenSuggestion(suggestion)

                await MainActor.run {
                    cachedSuggestion = softenedSuggestion.isEmpty ? nil : softenedSuggestion
                    isRefreshingSuggestion = false
                    withAnimation(.easeInOut(duration: 0.18)) {
                        bubbleState = .suggestion
                    }
                }
            } catch {
                await MainActor.run {
                    isRefreshingSuggestion = false
                    bubbleState = .emotion
                }
                // Home stays calm on network failure and keeps the original emotional text.
            }
        }
    }

    private func softenSuggestion(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        if trimmed.hasPrefix("先") {
            return "可以" + trimmed
        }

        return trimmed
    }

    private func fallbackSuggestion(for attemptCount: Int) -> String {
        let message: String

        switch attemptCount {
        case 7...:
            message = "要不要写一个最新想做的，或者我们先放松一会儿"
        case 6:
            let options = [
                "好像有点难选，要不要先随便推进一点点",
                "如果现在不好选，可以先做一件最简单的事"
            ]
            message = options.randomElement() ?? options[0]
        default:
            let options = [
                "要不要先随便选一件最轻松的开始一下",
                "可以先挑一件最不费力的事情做一点点"
            ]
            message = options.randomElement() ?? options[0]
        }

        return softenSuggestion(message)
    }

    private func showSuccessToast(_ message: String) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
            splitTaskSuccessMessage = message
        }

        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: 1_500_000_000)
            guard splitTaskSuccessMessage == message else { return }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.22)) {
                    splitTaskSuccessMessage = nil
                }
            }
        }
    }
}

private struct HomeDialogueTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.14),
            control: CGPoint(x: rect.maxX - rect.width * 0.10, y: rect.minY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.maxX - rect.width * 0.03, y: rect.maxY - rect.height * 0.04)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY),
            control: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY - rect.height * 0.06)
        )
        return path
    }
}

#Preview {
    HomeSceneView()
        .environmentObject(FocusPetStore())
}
