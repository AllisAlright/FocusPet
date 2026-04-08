import SwiftUI

private enum HistoryFilter: String, CaseIterable, Identifiable {
    case all
    case completed
    case unfinished
    case focus

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:
            "全部"
        case .completed:
            "完成"
        case .unfinished:
            "未完成"
        case .focus:
            "专注"
        }
    }
}

private struct HistoryTaskRoute: Identifiable {
    let taskID: UUID
    let id = UUID()
}

struct HistoryPlaceholderView: View {
    @EnvironmentObject private var store: FocusPetStore

    @State private var selectedFilter: HistoryFilter = .all
    @State private var taskRoute: HistoryTaskRoute?
    @State private var searchText = ""
    @State private var pendingDeleteTask: TaskItem?
    @State private var recentlyDeletedTask: TaskItem?

    var body: some View {
        FocusPetSceneScaffold(title: nil, subtitle: nil) {
            if !isSearching {
                FocusPetCompanionHeader(
                    petType: store.settings.defaultPet,
                    eyebrow: "安静档案角",
                    title: "做过的事，都在这里",
                    message: "记录做完的，也能捡起没完成的"
                )

                SoftPanel {
                    Picker("历史筛选", selection: $selectedFilter) {
                        ForEach(HistoryFilter.allCases) { filter in
                            Text(filter.displayName).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            if isSearching {
                searchResultsContent
            } else {
                if shouldShowCompleted {
                    completedSection
                }

                if shouldShowUnfinished {
                    unfinishedSection
                }

                if shouldShowFocusRecords {
                    focusHistorySection
                }

                if isCompletelyEmpty {
                    emptyState
                }
            }
        }
        .navigationTitle("历史事项")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索历史事项")
        .sheet(item: $taskRoute) { route in
            if let task = store.task(with: route.taskID) {
                NavigationStack {
                    TaskArchiveDetailView(task: task)
                }
            }
        }
        .alert("删除这个内容？", isPresented: pendingDeleteBinding) {
            Button("取消", role: .cancel) {
                pendingDeleteTask = nil
            }
            Button("删除", role: .destructive) {
                if let task = pendingDeleteTask {
                    store.softDeleteTask(id: task.id)
                    recentlyDeletedTask = task
                }
                pendingDeleteTask = nil
            }
        } message: {
            Text("删除后可在「最近删除」中恢复")
        }
        .overlay(alignment: .bottom) {
            if let task = recentlyDeletedTask {
                UndoToastView(title: "已删除", actionTitle: "撤销") {
                    store.restoreTask(id: task.id)
                    recentlyDeletedTask = nil
                }
                .padding(.horizontal, FocusPetTheme.Spacing.large)
                .padding(.bottom, 14)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: recentlyDeletedTask?.id)
        .task(id: recentlyDeletedTask?.id) {
            guard let toastID = recentlyDeletedTask?.id else { return }
            try? await _Concurrency.Task.sleep(nanoseconds: 3_000_000_000)
            if recentlyDeletedTask?.id == toastID {
                recentlyDeletedTask = nil
            }
        }
    }

    private var shouldShowCompleted: Bool {
        selectedFilter == .all || selectedFilter == .completed
    }

    private var shouldShowUnfinished: Bool {
        selectedFilter == .all || selectedFilter == .unfinished
    }

    private var shouldShowFocusRecords: Bool {
        selectedFilter == .all || selectedFilter == .focus
    }

    private var isCompletelyEmpty: Bool {
        switch selectedFilter {
        case .all:
            store.completedTasks.isEmpty && store.unfinishedHistoryTasks.isEmpty && store.focusSessions.isEmpty
        case .completed:
            store.completedTasks.isEmpty
        case .unfinished:
            store.unfinishedHistoryTasks.isEmpty
        case .focus:
            store.focusSessions.isEmpty
        }
    }

    private var searchKeyword: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).localizedLowercase
    }

    private var isSearching: Bool {
        !searchKeyword.isEmpty
    }

    private var filteredCompletedTasks: [TaskItem] {
        store.completedTasks.filter(matchesTaskSearch)
    }

    private var filteredUnfinishedTasks: [TaskItem] {
        store.unfinishedHistoryTasks.filter(matchesTaskSearch)
    }

    private var filteredFocusSessions: [FocusSession] {
        store.focusSessions.filter(matchesFocusSearch)
    }

    private var searchResultsContent: some View {
        Group {
            if filteredCompletedTasks.isEmpty && filteredUnfinishedTasks.isEmpty && filteredFocusSessions.isEmpty {
                searchEmptyState
            } else {
                if !filteredCompletedTasks.isEmpty {
                    completedSection(tasks: filteredCompletedTasks)
                }

                if !filteredUnfinishedTasks.isEmpty {
                    unfinishedSection(tasks: filteredUnfinishedTasks)
                }

                if !filteredFocusSessions.isEmpty {
                    focusHistorySection(sessions: filteredFocusSessions)
                }
            }
        }
    }

    private var emptyState: some View {
        SoftPanel {
            Text("这里还没有内容")
                .font(FocusPetTheme.Typography.headline)
                .foregroundStyle(FocusPetTheme.Palette.ink)

            Text("已经完成的、暂停的、逾期的事项和专注记录，之后都会在这里慢慢留下来。")
                .font(FocusPetTheme.Typography.subheadline)
                .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var searchEmptyState: some View {
        SoftPanel {
            Text("没有找到相关记录")
                .font(FocusPetTheme.Typography.headline)
                .foregroundStyle(FocusPetTheme.Palette.ink)

            Text("换个关键词试试")
                .font(FocusPetTheme.Typography.subheadline)
                .foregroundStyle(FocusPetTheme.Palette.inkSoft)
        }
    }

    private var completedSection: some View {
        completedSection(tasks: store.completedTasks)
    }

    private func completedSection(tasks: [TaskItem]) -> some View {
        SoftPanel {
            HStack {
                Text("已完成")
                    .font(FocusPetTheme.Typography.headline)
                    .foregroundStyle(FocusPetTheme.Palette.ink)

                Spacer(minLength: 0)

                Text("\(tasks.count)")
                    .font(FocusPetTheme.Typography.caption)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
            }

            if tasks.isEmpty {
                Text("还没有已经完成的事项。")
                    .font(FocusPetTheme.Typography.subheadline)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
            } else {
                ForEach(tasks) { task in
                    completedTaskCard(task)
                }
            }
        }
    }

    private var unfinishedSection: some View {
        unfinishedSection(tasks: store.unfinishedHistoryTasks)
    }

    private func unfinishedSection(tasks: [TaskItem]) -> some View {
        SoftPanel {
            HStack {
                Text("未完成记录")
                    .font(FocusPetTheme.Typography.headline)
                    .foregroundStyle(FocusPetTheme.Palette.ink)

                Spacer(minLength: 0)

                Text("\(tasks.count)")
                    .font(FocusPetTheme.Typography.caption)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
            }

            if tasks.isEmpty {
                Text("目前没有已暂停或已逾期的事项。")
                    .font(FocusPetTheme.Typography.subheadline)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
            } else {
                ForEach(tasks) { task in
                    unfinishedTaskCard(task)
                }
            }
        }
    }

    private var focusHistorySection: some View {
        focusHistorySection(sessions: store.focusSessions)
    }

    private func focusHistorySection(sessions: [FocusSession]) -> some View {
        SoftPanel {
            HStack {
                Text("专注记录")
                    .font(FocusPetTheme.Typography.headline)
                    .foregroundStyle(FocusPetTheme.Palette.ink)

                Spacer(minLength: 0)

                Text("\(sessions.count)")
                    .font(FocusPetTheme.Typography.caption)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
            }

            if sessions.isEmpty {
                Text("这里还没有专注记录。")
                    .font(FocusPetTheme.Typography.subheadline)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
            } else {
                ForEach(sessions) { session in
                    focusRecordCard(session)
                }
            }
        }
    }

    private func completedTaskCard(_ task: TaskItem) -> some View {
        Button {
            taskRoute = HistoryTaskRoute(taskID: task.id)
        } label: {
            SoftListItem {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(task.title)
                            .font(FocusPetTheme.Typography.headline)
                            .foregroundStyle(FocusPetTheme.Palette.ink)

                        if let notesPreview = task.notesPreview {
                            Text(notesPreview)
                                .font(FocusPetTheme.Typography.subheadline)
                                .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                                .lineLimit(2)
                        }
                    }

                    Spacer(minLength: 8)

                    Text("100%")
                        .font(FocusPetTheme.Typography.subheadline)
                        .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                }

                progressBar(progress: 1)

                HStack(spacing: 8) {
                    metaPill(task.spentTimeText)
                    metaPill("完成于 \(DateDisplayFormatter.relativeChineseDateTime(from: task.updatedAt))")
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func unfinishedTaskCard(_ task: TaskItem) -> some View {
        SoftListItem {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(FocusPetTheme.Typography.headline)
                        .foregroundStyle(FocusPetTheme.Palette.ink)

                    if let notesPreview = task.notesPreview {
                        Text(notesPreview)
                            .font(FocusPetTheme.Typography.subheadline)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 8)

                metaPill(task.statusText)
            }

            progressBar(progress: task.progress)

            HStack(spacing: 8) {
                metaPill(task.progressText)
                metaPill(task.spentTimeText)
                if let dueSummaryText = task.dueSummaryText {
                    metaPill(dueSummaryText)
                }
            }

            HStack(spacing: 10) {
                Button {
                    store.reactivateTask(id: task.id)
                } label: {
                    Text("重新激活")
                        .font(FocusPetTheme.Typography.caption)
                        .foregroundStyle(FocusPetTheme.Palette.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(FocusPetTheme.Palette.warm.opacity(0.72))
                        )
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                Menu {
                    Button("重新激活") {
                        store.reactivateTask(id: task.id)
                    }

                    Button("删除", role: .destructive) {
                        pendingDeleteTask = task
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            taskRoute = HistoryTaskRoute(taskID: task.id)
        }
    }

    private func focusRecordCard(_ session: FocusSession) -> some View {
        SoftListItem {
            Text(store.task(with: session.taskID)?.title ?? "自由专注")
                .font(FocusPetTheme.Typography.headline)
                .foregroundStyle(FocusPetTheme.Palette.ink)

            Text(focusRecordText(for: session))
                .font(FocusPetTheme.Typography.subheadline)
                .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func focusRecordText(for session: FocusSession) -> String {
        let minutes = max(session.durationMinutes, 1)
        return "\(session.timerMode.displayName) · \(minutes)分钟 · \(session.historyTimestampText)"
    }

    private func matchesTaskSearch(_ task: TaskItem) -> Bool {
        let title = task.title.localizedLowercase
        let notes = task.notes.localizedLowercase
        return title.contains(searchKeyword) || notes.contains(searchKeyword)
    }

    private func matchesFocusSearch(_ session: FocusSession) -> Bool {
        let timerMode = session.timerMode.displayName.localizedLowercase
        let taskTitle = (store.task(with: session.taskID)?.title ?? "自由专注").localizedLowercase
        return timerMode.contains(searchKeyword) || taskTitle.contains(searchKeyword)
    }

    private func progressBar(progress: Double) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(FocusPetTheme.Palette.progressTrack)

                Capsule()
                    .fill(FocusPetTheme.Palette.progressFill)
                    .frame(width: proxy.size.width * progress.clamped(to: 0 ... 1))
            }
        }
        .frame(height: 10)
    }

    private func metaPill(_ text: String) -> some View {
        Text(text)
            .font(FocusPetTheme.Typography.caption)
            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.46))
            )
    }

    private var pendingDeleteBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteTask != nil },
            set: { newValue in
                if !newValue {
                    pendingDeleteTask = nil
                }
            }
        )
    }
}
