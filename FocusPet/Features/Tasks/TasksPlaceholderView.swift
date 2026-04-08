import SwiftUI

struct TasksPlaceholderView: View {
    @EnvironmentObject private var store: FocusPetStore

    @State private var editorRoute: TaskEditorRoute?
    @State private var searchText = ""
    @State private var pendingDeleteTask: TaskItem?
    @State private var recentlyDeletedTask: TaskItem?

    var body: some View {
        FocusPetSceneScaffold(title: nil, subtitle: nil) {
            if !isSearching {
                FocusPetCompanionHeader(
                    petType: store.settings.defaultPet,
                    eyebrow: "温和推进板",
                    title: "今天也往前推进一点",
                    message: "把事项整理起来，慢慢推进就好"
                )

                SoftPanel {
                    NavigationLink {
                        TaskRecentlyDeletedView()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(FocusPetTheme.Palette.inkSoft)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("最近删除")
                                    .font(FocusPetTheme.Typography.headline)
                                    .foregroundStyle(FocusPetTheme.Palette.ink)

                                Text(store.deletedTasks.isEmpty ? "这里暂时是空的" : "有 \(store.deletedTasks.count) 条事项在这里")
                                    .font(FocusPetTheme.Typography.subheadline)
                                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                            }

                            Spacer(minLength: 0)

                            if !store.deletedTasks.isEmpty {
                                Text("\(store.deletedTasks.count)")
                                    .font(FocusPetTheme.Typography.caption)
                                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.42))
                                    )
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if filteredActiveTasks.isEmpty {
                if !isSearching {
                    emptyState
                } else {
                    emptyState
                }
            } else {
                if !isSearching {
                    taskSection(title: "进行中", subtitle: "正在慢慢推进的事情", tasks: filteredActiveTasks)
                } else {
                    searchResultsSection
                }
            }
        }
        .navigationTitle("待办事项")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索事项")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editorRoute = TaskEditorRoute(taskID: nil)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            store.cleanupDeletedTasksIfNeeded()
        }
        .sheet(item: $editorRoute) { route in
            TaskEditorView(taskID: route.taskID)
                .environmentObject(store)
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

    private var emptyState: some View {
        SoftPanel {
            Text(searchKeyword.isEmpty ? "现在还没有正在推进的事项" : "没有找到相关事项")
                .font(FocusPetTheme.Typography.headline)
                .foregroundStyle(FocusPetTheme.Palette.ink)

            Text(searchKeyword.isEmpty ? "右上角点一下，就能先记下一件想慢慢完成的事。" : "换个关键词试试。")
                .font(FocusPetTheme.Typography.subheadline)
                .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var searchResultsSection: some View {
        SoftPanel {
            HStack {
                Text("搜索结果")
                    .font(FocusPetTheme.Typography.headline)
                    .foregroundStyle(FocusPetTheme.Palette.ink)

                Spacer(minLength: 0)

                Text("\(filteredActiveTasks.count)")
                    .font(FocusPetTheme.Typography.caption)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
            }

            ForEach(filteredActiveTasks) { task in
                taskCard(task, highlight: searchKeyword)
            }
        }
    }

    private var searchKeyword: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).localizedLowercase
    }

    private var isSearching: Bool {
        !searchKeyword.isEmpty
    }

    private var filteredVisibleTasks: [TaskItem] {
        guard !searchKeyword.isEmpty else { return store.currentTasks }
        return store.currentTasks.filter(matchesSearch)
    }

    private var filteredActiveTasks: [TaskItem] {
        filteredVisibleTasks.filter { $0.resolvedStatus() == .active }
    }

    private func matchesSearch(_ task: TaskItem) -> Bool {
        let title = task.title.localizedLowercase
        let notes = task.notes.localizedLowercase
        return title.contains(searchKeyword) || notes.contains(searchKeyword)
    }

    @ViewBuilder
    private func taskSection(title: String, subtitle: String, tasks: [TaskItem]) -> some View {
        if !tasks.isEmpty {
            SoftPanel {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(FocusPetTheme.Typography.headline)
                        .foregroundStyle(FocusPetTheme.Palette.ink)

                    if !isSearching {
                        Text(subtitle)
                            .font(FocusPetTheme.Typography.caption)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                    }
                }

                ForEach(tasks) { task in
                    taskCard(task, highlight: searchKeyword)
                        .contextMenu {
                            Button("编辑") {
                                editorRoute = TaskEditorRoute(taskID: task.id)
                            }

                            if task.resolvedStatus() == .paused {
                                Button("恢复") {
                                    store.resumeTask(id: task.id)
                                }
                            } else if !task.isCompleted {
                                Button("暂停") {
                                    store.pauseTask(id: task.id)
                                }
                            }

                            if !task.isCompleted {
                                Button("标记完成") {
                                    store.completeTask(id: task.id)
                                }
                            }

                            Button("删除", role: .destructive) {
                                pendingDeleteTask = task
                            }
                        }
                }
            }
        }
    }

    private func taskCard(_ task: TaskItem, highlight: String) -> some View {
        SoftListItem {
            HStack(alignment: .top, spacing: FocusPetTheme.Spacing.small) {
                VStack(alignment: .leading, spacing: FocusPetTheme.Spacing.small) {
                    HStack(alignment: .top, spacing: 8) {
                        highlightedText(
                            task.title,
                            keyword: highlight,
                            font: FocusPetTheme.Typography.headline
                        )
                        .lineLimit(2)

                        Spacer(minLength: 8)

                        Text(task.progressText)
                            .font(FocusPetTheme.Typography.subheadline)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                    }

                    if let notesPreview = task.notesPreview {
                        highlightedText(
                            notesPreview,
                            keyword: highlight,
                            font: FocusPetTheme.Typography.subheadline,
                            primaryColor: FocusPetTheme.Palette.inkSoft
                        )
                            .lineLimit(2)
                    }

                    progressBar(progress: task.progress)

                    HStack(spacing: 8) {
                        taskMetaPill(task.spentTimeText)

                        if let dueSummaryText = task.dueSummaryText {
                            taskMetaPill(dueSummaryText)
                        }
                    }

                    HStack(spacing: 10) {
                        Button {
                            editorRoute = TaskEditorRoute(taskID: task.id)
                        } label: {
                            Text("编辑")
                                .font(FocusPetTheme.Typography.caption)
                                .foregroundStyle(FocusPetTheme.Palette.ink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color.white.opacity(0.68))
                                )
                        }
                        .buttonStyle(.plain)

                        if task.enableFocus {
                            NavigationLink {
                                FocusSetupView(preselectedTaskID: task.id)
                            } label: {
                                Text("开始专注")
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
                        }

                        Spacer(minLength: 0)

                        Menu {
                            if task.resolvedStatus() == .paused {
                                Button("恢复") {
                                    store.resumeTask(id: task.id)
                                }
                            } else {
                                Button("暂停") {
                                    store.pauseTask(id: task.id)
                                }
                            }

                            Button("标记完成") {
                                store.completeTask(id: task.id)
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
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editorRoute = TaskEditorRoute(taskID: task.id)
        }
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

    private func taskMetaPill(_ text: String) -> some View {
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

    private func highlightedText(
        _ text: String,
        keyword: String,
        font: Font,
        primaryColor: Color = FocusPetTheme.Palette.ink
    ) -> Text {
        guard !keyword.isEmpty,
              let range = text.localizedStandardRange(of: keyword)
        else {
            return Text(text)
                .font(font)
                .foregroundColor(primaryColor)
        }

        let before = String(text[..<range.lowerBound])
        let match = String(text[range])
        let after = String(text[range.upperBound...])

        return Text(before)
            .font(font)
            .foregroundColor(primaryColor)
        + Text(match)
            .font(font)
            .foregroundColor(FocusPetTheme.Palette.peach)
        + Text(after)
            .font(font)
            .foregroundColor(primaryColor)
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

private struct TaskEditorRoute: Identifiable {
    let taskID: UUID?
    let id = UUID()
}
