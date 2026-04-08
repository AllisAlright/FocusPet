import SwiftUI

private struct MemoEditorContext: Identifiable {
    let id = UUID()
    let memoID: UUID?
    let content: String
    let isPinned: Bool

    static let create = MemoEditorContext(memoID: nil, content: "", isPinned: false)
}

private struct MemoTaskConversionRoute: Identifiable {
    let memo: MemoItem
    let id = UUID()
}

struct MemoPlaceholderView: View {
    @EnvironmentObject private var store: FocusPetStore
    @State private var editorContext: MemoEditorContext?
    @State private var conversionRoute: MemoTaskConversionRoute?
    @State private var searchText = ""
    @State private var pendingDeleteMemo: MemoItem?
    @State private var recentlyDeletedMemo: MemoItem?

    var body: some View {
        FocusPetSceneScaffold(title: nil, subtitle: nil) {
            FocusPetCompanionHeader(
                petType: store.settings.defaultPet,
                eyebrow: "雨天小角落",
                title: "把念头轻轻放下",
                message: "先记下来，未来可以整理成任务"
            )

            SoftPanel {
                NavigationLink {
                    MemoRecentlyDeletedView()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("最近删除")
                                .font(FocusPetTheme.Typography.headline)
                                .foregroundStyle(FocusPetTheme.Palette.ink)

                            Text(store.deletedMemoItems.isEmpty ? "这里暂时是空的" : "有 \(store.deletedMemoItems.count) 条备忘在这里")
                                .font(FocusPetTheme.Typography.subheadline)
                                .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                        }

                        Spacer(minLength: 0)

                        if !store.deletedMemoItems.isEmpty {
                            Text("\(store.deletedMemoItems.count)")
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

            if filteredPinnedMemos.isEmpty && filteredRegularMemos.isEmpty {
                SoftPanel {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(searchText.isEmpty ? "还没有备忘" : "没有找到相关备忘")
                            .font(FocusPetTheme.Typography.headline)
                            .foregroundStyle(FocusPetTheme.Palette.ink)

                        Text(searchText.isEmpty ? "先写下一个念头，稍后再慢慢整理。" : "换个词试试，或新建一条备忘。")
                            .font(FocusPetTheme.Typography.subheadline)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                    }
                }
            } else {
                if !filteredPinnedMemos.isEmpty {
                    SoftPanel {
                        HStack {
                            Text("置顶")
                                .font(FocusPetTheme.Typography.headline)
                                .foregroundStyle(FocusPetTheme.Palette.ink)

                            Spacer(minLength: 0)

                            Text("\(filteredPinnedMemos.count)")
                                .font(FocusPetTheme.Typography.caption)
                                .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                        }

                        ForEach(filteredPinnedMemos) { memo in
                            memoCard(memo)
                        }
                    }
                }

                if !filteredRegularMemos.isEmpty {
                    SoftPanel {
                        HStack {
                            Text("全部备忘")
                                .font(FocusPetTheme.Typography.headline)
                                .foregroundStyle(FocusPetTheme.Palette.ink)

                            Spacer(minLength: 0)

                            Text("\(filteredRegularMemos.count)")
                                .font(FocusPetTheme.Typography.caption)
                                .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                        }

                        ForEach(filteredRegularMemos) { memo in
                            memoCard(memo)
                        }
                    }
                }
            }
        }
        .navigationTitle("备忘录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editorContext = .create
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(FocusPetTheme.Palette.ink)
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索备忘")
        .onAppear {
            store.cleanupDeletedMemosIfNeeded()
        }
        .sheet(item: $editorContext) { context in
            MemoEditorView(
                title: context.memoID == nil ? "新建备忘" : "编辑备忘",
                memo: context.memoID.flatMap { store.memo(with: $0) },
                initialContent: context.content,
                initialPinned: context.isPinned,
                onSave: { content, isPinned in
                    if let memoID = context.memoID {
                        store.updateMemo(id: memoID, content: content, isPinned: isPinned)
                    } else {
                        store.createMemo(content: content, isPinned: isPinned)
                    }
                },
                onDelete: context.memoID.map { memoID in
                    { store.softDeleteMemo(id: memoID) }
                }
            )
            .environmentObject(store)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $conversionRoute) { route in
            MemoToTaskConversionView(memo: route.memo)
                .environmentObject(store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("删除这个内容？", isPresented: pendingDeleteBinding) {
            Button("取消", role: .cancel) {
                pendingDeleteMemo = nil
            }
            Button("删除", role: .destructive) {
                if let memo = pendingDeleteMemo {
                    store.softDeleteMemo(id: memo.id)
                    recentlyDeletedMemo = memo
                }
                pendingDeleteMemo = nil
            }
        } message: {
            Text("删除后可在「最近删除」中恢复")
        }
        .overlay(alignment: .bottom) {
            if let memo = recentlyDeletedMemo {
                UndoToastView(title: "已删除", actionTitle: "撤销") {
                    store.restoreMemo(id: memo.id)
                    recentlyDeletedMemo = nil
                }
                .padding(.horizontal, FocusPetTheme.Spacing.large)
                .padding(.bottom, 14)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: recentlyDeletedMemo?.id)
        .task(id: recentlyDeletedMemo?.id) {
            guard let toastID = recentlyDeletedMemo?.id else { return }
            try? await _Concurrency.Task.sleep(nanoseconds: 3_000_000_000)
            if recentlyDeletedMemo?.id == toastID {
                recentlyDeletedMemo = nil
            }
        }
    }

    private var filteredActiveMemos: [MemoItem] {
        let activeMemos = store.activeMemoItems
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return activeMemos
        }

        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines).localizedLowercase
        return activeMemos.filter { $0.content.localizedLowercase.contains(keyword) }
    }

    private var filteredPinnedMemos: [MemoItem] {
        filteredActiveMemos.filter(\.isPinned)
    }

    private var filteredRegularMemos: [MemoItem] {
        filteredActiveMemos.filter { !$0.isPinned }
    }

    private func memoCard(_ memo: MemoItem) -> some View {
        Button {
            editorContext = MemoEditorContext(memoID: memo.id, content: memo.content, isPinned: memo.isPinned)
        } label: {
            SoftListItem {
                HStack(alignment: .top, spacing: 8) {
                    Text(memo.previewText.isEmpty ? "空白备忘" : memo.previewText)
                        .font(FocusPetTheme.Typography.body)
                        .foregroundStyle(FocusPetTheme.Palette.ink)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)

                    if memo.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                    }
                }

                Text(memo.updatedAtText)
                    .font(FocusPetTheme.Typography.caption)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("删除", role: .destructive) {
                pendingDeleteMemo = memo
            }

            Button(memo.isPinned ? "取消置顶" : "置顶") {
                store.togglePin(forMemoID: memo.id)
            }
            .tint(FocusPetTheme.Palette.peach)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button("加入待办") {
                conversionRoute = MemoTaskConversionRoute(memo: memo)
            }
            .tint(FocusPetTheme.Palette.sage)
        }
        .contextMenu {
            Button(memo.isPinned ? "取消置顶" : "置顶") {
                store.togglePin(forMemoID: memo.id)
            }

            Button("加入待办") {
                conversionRoute = MemoTaskConversionRoute(memo: memo)
            }

            Button("删除", role: .destructive) {
                pendingDeleteMemo = memo
            }
        }
    }

    private var pendingDeleteBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteMemo != nil },
            set: { newValue in
                if !newValue {
                    pendingDeleteMemo = nil
                }
            }
        )
    }
}
