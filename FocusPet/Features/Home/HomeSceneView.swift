import SwiftUI

private enum HomeSceneRoute: Hashable {
    case memo
    case tasks
    case focus(taskID: UUID? = nil, suggestedMinutes: Int? = nil)
    case history
    case chat
}

struct HomeSceneView: View {
    @EnvironmentObject private var store: FocusPetStore
    @State private var path: [HomeSceneRoute] = []
    @State private var showPetSheet = false
    @State private var petMood: PetMood = .neutral
    @State private var companionMessageIndex = 0

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
                }
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: HomeSceneRoute.self) { route in
                    destinationView(for: route)
                }
                .onAppear {
                    store.registerHomeOpened()
                }
                .onChange(of: store.settings.defaultPet) { _, _ in
                    companionMessageIndex = 0
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
            }
        }
    }

    private func roomScene(compact: Bool) -> some View {
        GeometryReader { proxy in
            let topCardsTop = compact ? 28.0 : 32.0
            let petCenterY = proxy.size.height * (compact ? 0.49 : 0.50)
            let petSectionTop = petCenterY - (compact ? 76 : 88)
            let petFrameHeight = compact ? 148.0 : 168.0
            let bottomCardsBottom = compact ? 12.0 : 16.0
            let agentPanelBottom = bottomCardsBottom + (compact ? 150.0 : 164.0)

            ZStack {
                VStack(spacing: compact ? 28 : 32) {
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
                        .padding(.horizontal, compact ? 12 : 14)
                }
                .padding(.top, topCardsTop)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                ZStack {
                    floorShadow
                        .offset(y: 80)

                    PetCharacterView(petType: store.settings.defaultPet, mood: petMood)
                        .scaleEffect(compact ? 0.82 : 0.92)
                        .onTapGesture {
                            rotateCompanionMessage(for: store.settings.defaultPet)
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
                    .offset(x: compact ? 74 : 82, y: compact ? 76 : 86)
                    .zIndex(1)
                }
                .frame(height: petFrameHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .offset(y: petSectionTop)

                agentPanel(compact: compact)
                    .padding(.horizontal, compact ? 12 : 14)
                    .padding(.bottom, agentPanelBottom)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .zIndex(2)

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
                        action: { path.append(.focus()) }
                    )
                }
                .padding(.horizontal, compact ? 14 : 16)
                .padding(.bottom, bottomCardsBottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
    }

    private func agentPanel(compact: Bool) -> some View {
        PetAgentLauncherBar(
            petType: store.settings.defaultPet
        ) {
            path.append(.chat)
        }
        .frame(maxWidth: .infinity)
    }

    private func dialogueCard(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            bubbleContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, compact ? 10 : 12)
        .frame(maxWidth: .infinity, minHeight: compact ? 70 : 74, alignment: .leading)
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
        case let .focus(taskID, suggestedMinutes):
            FocusSetupView(
                preselectedTaskID: taskID,
                initialCountdownMinutes: suggestedMinutes
            )
        case .history:
            HistoryPlaceholderView()
        case .chat:
            PetChatView { taskID, suggestedMinutes in
                path.append(.focus(taskID: taskID, suggestedMinutes: suggestedMinutes))
            }
        }
    }

    private var companionMessage: String {
        let messages = companionMessages(for: store.settings.defaultPet)
        guard messages.indices.contains(companionMessageIndex) else {
            return messages.first ?? "我在这里。"
        }
        return messages[companionMessageIndex]
    }

    @ViewBuilder
    private var bubbleContent: some View {
        Text(companionMessage)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(FocusPetTheme.Palette.ink)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
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

    private func rotateCompanionMessage(for petType: PetType) {
        let messages = companionMessages(for: petType)
        guard messages.count > 1 else {
            companionMessageIndex = 0
            return
        }

        var nextIndex = Int.random(in: 0..<messages.count)
        if nextIndex == companionMessageIndex {
            nextIndex = (nextIndex + 1) % messages.count
        }

        withAnimation(.easeInOut(duration: 0.18)) {
            companionMessageIndex = nextIndex
        }
    }

    private func companionMessages(for petType: PetType) -> [String] {
        switch petType {
        case .rabbit:
            return [
                "我在这里。慢慢来就好。",
                "先不用急，我们看一小步。",
                "今天也可以只前进一点点。",
                "呼吸一下，我陪你理顺。",
                "没做完也没关系，可以续上。",
                "先把眼前这一格放清楚。",
                "你不用一个人扛着。",
                "先坐稳，我们慢慢看。",
                "小小开始，也算开始。",
                "我会陪你把它放轻一点。",
                "今天已经有一点进展啦。",
                "心乱的时候，先记下一句。",
                "不用马上变厉害，先开始。",
                "我们先找最容易的一步。",
                "慢慢推进，也很好。",
                "累了就先停一会儿。",
                "这件事可以一点点来。",
                "我在旁边，别急。",
                "先照顾好现在的自己。",
                "继续一点，也算前进。"
            ]
        case .cat:
            return [
                "我在。说吧。",
                "先别急，事情可以拆开。",
                "先看最关键的一件。",
                "这一步够小，可以开始。",
                "不用全想完，先判断。",
                "我会安静陪你看着。",
                "先把混乱收一收。",
                "这件事还有办法。",
                "今天先做最轻的一步。",
                "够了，先一点点。",
                "先坐稳，再决定。",
                "别急着评价自己。",
                "继续比重开省力。",
                "先挑一个能动的点。",
                "这房间还算安静。",
                "我没有催你，只是提醒。",
                "先保存，再慢慢整理。",
                "现在适合做小决定。",
                "把范围缩小一点。",
                "嗯，我看着呢。"
            ]
        case .dog:
            return [
                "我准备好陪你啦！",
                "先来一小步就很好。",
                "今天也可以慢慢动起来。",
                "我们一起把它变轻一点。",
                "好耶，先看看眼前这格！",
                "只做五分钟也算开始。",
                "你已经比刚才更近了。",
                "我在这儿，别怕开始。",
                "先挑最容易的那一步。",
                "做一点点，也很棒。",
                "今天有进展就值得记下。",
                "累了也可以先缓一缓。",
                "我陪你把节奏放慢。",
                "先别想太远，我们动一下。",
                "小小启动，也很厉害。",
                "我们可以再试一小轮。",
                "一件一件来就好。",
                "先把任务放清楚吧。",
                "我会陪你回来继续。",
                "出发不用很用力！"
            ]
        case .hamster:
            return [
                "哼，我才不是在等你。",
                "我只是在观察这个房间。",
                "先别把事情想成一大团。",
                "这团有点乱，先抓一根。",
                "哼，小步也算进度。",
                "我都帮你盯着呢。",
                "先滚一小格也行。",
                "不用逞强，电量要留着。",
                "这事可以先缩小一点。",
                "哼，开始一点也不是不行。",
                "先把最轻的那步拿出来。",
                "别一口气塞太多。",
                "这格还没那么可怕。",
                "我只是刚好有空。",
                "先记下，别让它跑掉。",
                "乱也没事，慢慢捋。",
                "先挑一个能下手的。",
                "哼，今天也能滚一格。",
                "做完一点再说大话。",
                "我在看着进度条呢。"
            ]
        }
    }

}

private struct PetAgentLauncherBar: View {
    let petType: PetType
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(FocusPetTheme.Palette.cloud.opacity(0.62))
                        .frame(width: 34, height: 34)

                    Image(systemName: "message.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                }

                Text("找\(petType.displayName)聊聊")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(FocusPetTheme.Palette.ink)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft.opacity(0.70))
            }
            .frame(maxWidth: .infinity)
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                FocusPetTheme.Palette.panel.opacity(0.62),
                                FocusPetTheme.Palette.cloud.opacity(0.42)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.62), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
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
