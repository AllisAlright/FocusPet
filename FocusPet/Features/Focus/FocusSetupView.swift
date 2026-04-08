import SwiftUI

struct FocusSetupView: View {
    @EnvironmentObject private var store: FocusPetStore

    let preselectedTaskID: UUID?

    @State private var selectedTaskID: UUID?
    @State private var searchText = ""
    @State private var timerMode: TimerMode
    @State private var countdownMinutes: Int

    init(preselectedTaskID: UUID? = nil) {
        self.preselectedTaskID = preselectedTaskID
        _selectedTaskID = State(initialValue: preselectedTaskID)
        _timerMode = State(initialValue: .countDown)
        _countdownMinutes = State(initialValue: 25)
    }

    var body: some View {
        FocusPetSceneScaffold(title: nil, subtitle: nil) {
            SoftPanel {
                HStack(alignment: .center, spacing: 12) {
                    PetAvatarBadge(petType: store.settings.defaultPet, size: .small)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("开始专注")
                            .font(FocusPetTheme.Typography.title)
                            .foregroundStyle(FocusPetTheme.Palette.ink)

                        Text(guidanceText)
                            .font(FocusPetTheme.Typography.subheadline)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if isTaskLocked {
                SoftPanel {
                    Text("这次将围绕这个事项专注")
                        .font(FocusPetTheme.Typography.headline)

                    if let lockedTask {
                        lockedTaskCard(lockedTask)
                    } else {
                        Text("这个事项当前不能直接开始专注。")
                            .font(FocusPetTheme.Typography.subheadline)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                    }
                }
            } else {
                SoftPanel {
                    Text("这次想专注什么")
                        .font(FocusPetTheme.Typography.headline)

                    Button {
                        selectedTaskID = nil
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: selectedTaskID == nil ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(selectedTaskID == nil ? FocusPetTheme.Palette.sage : FocusPetTheme.Palette.inkSoft)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("自由专注")
                                    .font(FocusPetTheme.Typography.headline)
                                    .foregroundStyle(FocusPetTheme.Palette.ink)

                               
                            }

                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)

                    if focusableTasks.isEmpty {
                        SoftListItem {
                            Text("还没有可专注的事项")
                                .font(FocusPetTheme.Typography.headline)
                                .foregroundStyle(FocusPetTheme.Palette.ink)

                            Text("你可以先自由专注，或把某件待办设为允许专注")
                                .font(FocusPetTheme.Typography.subheadline)
                                .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                        }
                    } else {
                        TextField("搜索事项", text: $searchText)
                            .font(FocusPetTheme.Typography.body)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                                    .fill(Color.white.opacity(0.55))
                            )

                        if displayedTasks.isEmpty && isSearching {
                            SoftListItem {
                                Text("没有找到相关事项")
                                    .font(FocusPetTheme.Typography.headline)
                                    .foregroundStyle(FocusPetTheme.Palette.ink)

                                Text("换个关键词试试")
                                    .font(FocusPetTheme.Typography.subheadline)
                                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                            }
                        } else if !displayedTasks.isEmpty {
                            ForEach(displayedTasks) { task in
                                focusTaskCard(task)
                            }
                        }
                    }
                }
            }

            SoftPanel {
                Text("计时方式")
                    .font(FocusPetTheme.Typography.headline)

                Picker("计时方式", selection: $timerMode) {
                    ForEach(TimerMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if timerMode == .countDown {
                    Stepper(value: $countdownMinutes, in: 5 ... 180, step: 5) {
                        Text("专注 \(countdownMinutes) 分钟")
                            .font(FocusPetTheme.Typography.body)
                            .foregroundStyle(FocusPetTheme.Palette.ink)
                    }

                    Text("可以从一个轻松的时长开始")
                        .font(FocusPetTheme.Typography.subheadline)
                        .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                } else {
                    Text("正计时会从 00:00 开始累计，适合开放式投入")
                        .font(FocusPetTheme.Typography.subheadline)
                        .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                }
            }

            SoftPanel {
                NavigationLink {
                    FocusSessionView(
                        taskID: selectedTaskID,
                        petType: store.settings.defaultPet,
                        timerMode: timerMode,
                        plannedDurationSeconds: timerMode == .countDown ? countdownMinutes * 60 : nil
                    )
                } label: {
                    Text("开始专注")
                        .font(FocusPetTheme.Typography.headline)
                        .foregroundStyle(FocusPetTheme.Palette.ink)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                                .fill(FocusPetTheme.Palette.warm.opacity(0.72))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("开始专注")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            timerMode = store.settings.defaultTimerMode
            countdownMinutes = store.settings.defaultCountdownMinutes
            if let selectedTaskID, !focusableTasks.contains(where: { $0.id == selectedTaskID }) {
                self.selectedTaskID = nil
            }
        }
    }

    private var isTaskLocked: Bool {
        preselectedTaskID != nil
    }

    private var lockedTask: Task? {
        guard let preselectedTaskID else { return nil }
        return focusableTasks.first { $0.id == preselectedTaskID }
    }

    private var guidanceText: String {
        "留一小段时间给自己"
    }

    private var searchKeyword: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).localizedLowercase
    }

    private var isSearching: Bool {
        !searchKeyword.isEmpty
    }

    private var focusableTasks: [Task] {
        store.focusEligibleTasks
    }

    private var recommendedTasks: [Task] {
        Array(store.recommendedFocusTasks.prefix(2))
    }

    private var filteredFocusableTasks: [Task] {
        guard isSearching else { return focusableTasks }
        return focusableTasks.filter(matchesSearch)
    }

    private var displayedTasks: [Task] {
        isSearching ? filteredFocusableTasks : recommendedTasks
    }

    private func matchesSearch(_ task: Task) -> Bool {
        let title = task.title.localizedLowercase
        let notes = task.notes.localizedLowercase
        return title.contains(searchKeyword) || notes.contains(searchKeyword)
    }

    private func focusTaskCard(_ task: Task) -> some View {
        Button {
            selectedTaskID = task.id
        } label: {
            SoftListItem {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: selectedTaskID == task.id ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(selectedTaskID == task.id ? FocusPetTheme.Palette.sage : FocusPetTheme.Palette.inkSoft)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(task.title)
                            .font(FocusPetTheme.Typography.headline)
                            .foregroundStyle(FocusPetTheme.Palette.ink)
                            .multilineTextAlignment(.leading)

                        if let notesPreview = task.notesPreview {
                            Text(notesPreview)
                                .font(FocusPetTheme.Typography.subheadline)
                                .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func lockedTaskCard(_ task: Task) -> some View {
        SoftListItem {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(FocusPetTheme.Palette.sage)

                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(FocusPetTheme.Typography.headline)
                        .foregroundStyle(FocusPetTheme.Palette.ink)
                        .multilineTextAlignment(.leading)

                    if let notesPreview = task.notesPreview {
                        Text(notesPreview)
                            .font(FocusPetTheme.Typography.subheadline)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }
}
