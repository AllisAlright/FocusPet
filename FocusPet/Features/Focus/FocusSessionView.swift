import SwiftUI

struct FocusSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: FocusPetStore
    @StateObject private var timerController: FocusTimerController
    @State private var didFinishSession = false
    @State private var completedSession: FocusSession?
    @State private var showEndConfirmation = false

    let taskID: UUID?
    let petType: PetType
    let timerMode: TimerMode
    let plannedDurationSeconds: Int?

    init(
        taskID: UUID?,
        petType: PetType,
        timerMode: TimerMode,
        plannedDurationSeconds: Int?
    ) {
        self.taskID = taskID
        self.petType = petType
        self.timerMode = timerMode
        self.plannedDurationSeconds = plannedDurationSeconds
        _timerController = StateObject(
            wrappedValue: FocusTimerController(
                timerMode: timerMode,
                plannedDurationSeconds: plannedDurationSeconds
            )
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top
            let compact = proxy.size.width < 390

            ZStack {
                sharedFocusBackground
                    .ignoresSafeArea()

                VStack(spacing: compact ? 14 : 18) {
                    VStack(spacing: 8) {
                        Text(taskTitle)
                            .font(compact ? FocusPetTheme.Typography.title : FocusPetTheme.Typography.hero())
                            .foregroundStyle(sessionForegroundColor)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)

                        Text(sessionMoodText)
                            .font(FocusPetTheme.Typography.subheadline)
                            .foregroundStyle(sessionForegroundColor.opacity(0.82))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(headerMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                    Spacer(minLength: compact ? 12 : 20)

                    ZStack(alignment: .bottom) {
                        petPlatform

                        PetCharacterView(petType: petType)
                            .scaleEffect(compact ? 0.8 : 0.86)
                            .frame(height: compact ? 176 : 190)
                            .offset(y: -10)
                    }
                    .frame(height: compact ? 220 : 236)

                    Spacer(minLength: compact ? 12 : 18)

                    VStack(spacing: 12) {
                        Text(mainTimerText)
                            .font(FocusPetTheme.Typography.timer)
                            .monospacedDigit()
                            .foregroundStyle(sessionForegroundColor)

                        Text(secondaryTimerText)
                            .font(FocusPetTheme.Typography.subheadline)
                            .foregroundStyle(sessionForegroundColor.opacity(0.82))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(panelMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(sessionForegroundColor.opacity(0.12), lineWidth: 1)
                    )

                    Button {
                        showEndConfirmation = true
                    } label: {
                        Text("结束这轮")
                            .font(FocusPetTheme.Typography.headline)
                            .foregroundStyle(FocusPetTheme.Palette.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, topInset)
                .padding(.bottom, 20)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                guard store.canStartFocus(taskID: taskID) else {
                    dismiss()
                    return
                }
                store.registerFocusStarted(taskID: taskID)
                timerController.start {
                    finishSession()
                }
            }
            .onDisappear {
                if !didFinishSession {
                    timerController.stop()
                }
            }
            .fullScreenCover(item: $completedSession) { session in
                FocusCompletionView(
                    session: session,
                    task: store.task(with: session.taskID),
                    onComplete: { action in
                        let didAdvance: Bool
                        switch action {
                        case .continueRound(let advanced), .rest(let advanced):
                            didAdvance = advanced
                        }

                        store.finishFocusSession(session, didAdvance: didAdvance)
                        completedSession = nil

                        switch action {
                        case .continueRound:
                            restartSession()
                        case .rest:
                            dismiss()
                        }
                    }
                )
                .environmentObject(store)
            }
            .sheet(isPresented: $showEndConfirmation) {
                FocusEndConfirmationSheet(
                    elapsedText: formattedTime(timerController.elapsedSeconds),
                    onContinue: {
                        showEndConfirmation = false
                    },
                    onEnd: {
                        showEndConfirmation = false
                        presentCompletion()
                    }
                )
                .presentationDetents([.height(248)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var taskTitle: String {
        store.task(with: taskID)?.title ?? "自由专注"
    }

    private var mainTimerText: String {
        switch timerMode {
        case .countUp:
            formattedTime(timerController.elapsedSeconds)
        case .countDown:
            formattedTime(timerController.remainingSeconds ?? 0)
        }
    }

    private var secondaryTimerText: String {
        "已专注 \(formattedTime(timerController.elapsedSeconds)) · \(DateDisplayFormatter.focusStartText(from: startDate))"
    }

    private var startDate: Date {
        Date.now.addingTimeInterval(TimeInterval(-timerController.elapsedSeconds))
    }

    private func finishSession() {
        presentCompletion()
    }

    private func presentCompletion() {
        guard !didFinishSession else { return }
        didFinishSession = true
        timerController.stop()

        // SceneType remains in the model for compatibility with existing local data.
        completedSession = FocusSession(
            taskID: taskID,
            petType: petType,
            sceneType: .rainyWindow,
            startedAt: startDate,
            endedAt: .now,
            durationSeconds: timerController.elapsedSeconds,
            timerMode: timerMode,
            plannedDurationSeconds: plannedDurationSeconds
        )
    }

    private func restartSession() {
        didFinishSession = false
        timerController.reset()
        store.registerFocusStarted(taskID: taskID)
        timerController.start {
            finishSession()
        }
    }

    private var sessionMoodText: String {
        switch petType {
        case .rabbit:
            return "慢一点也没关系"
        case .cat:
            return "集中注意力就更棒了"
        case .dog:
            return "先专心这一小段时间呀"
        case .hamster:
            return "一小格一小格地往前走"
        }
    }

    private func formattedTime(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var sharedFocusBackground: some View {
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
        }
    }

    private var sessionForegroundColor: Color {
        FocusPetTheme.Palette.ink
    }

    private var panelMaterial: Color {
        Color.white.opacity(0.68)
    }

    private var headerMaterial: Color {
        Color.white.opacity(0.52)
    }

    private var petPlatform: some View {
        Ellipse()
            .fill(Color.black.opacity(0.10))
            .frame(width: 176, height: 30)
            .blur(radius: 12)
            .offset(y: 5)
    }
}

private struct FocusEndConfirmationSheet: View {
    let elapsedText: String
    let onContinue: () -> Void
    let onEnd: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.white.opacity(0.8))
                .frame(width: 42, height: 5)

            VStack(spacing: 8) {
                Text("要结束这轮专注吗？")
                    .font(FocusPetTheme.Typography.title)
                    .foregroundStyle(FocusPetTheme.Palette.ink)

                Text("你已经专注了 \(elapsedText)")
                    .font(FocusPetTheme.Typography.subheadline)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
            }

            VStack(spacing: 10) {
                Button(action: onContinue) {
                    Text("继续专注")
                        .font(FocusPetTheme.Typography.headline)
                        .foregroundStyle(FocusPetTheme.Palette.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                                .fill(FocusPetTheme.Palette.warm.opacity(0.72))
                        )
                }
                .buttonStyle(.plain)

                Button(action: onEnd) {
                    Text("结束本轮")
                        .font(FocusPetTheme.Typography.subheadline)
                        .foregroundStyle(FocusPetTheme.Palette.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                                .fill(Color.white.opacity(0.5))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .presentationBackground(.ultraThinMaterial)
    }
}
