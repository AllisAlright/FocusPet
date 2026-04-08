import SwiftUI

struct TaskRecentlyDeletedView: View {
    @EnvironmentObject private var store: FocusPetStore
    @State private var pendingPermanentDeleteTask: TaskItem?

    var body: some View {
        FocusPetSceneScaffold(title: nil, subtitle: nil) {
            FocusPetCompanionHeader(
                petType: store.settings.defaultPet,
                eyebrow: "安静回收站",
                title: "最近删除",
                message: "这里的内容会在 7 天后自动删除"
            )

            if store.deletedTasks.isEmpty {
                SoftPanel {
                    Text("这里是空的")
                        .font(FocusPetTheme.Typography.headline)
                        .foregroundStyle(FocusPetTheme.Palette.ink)

                    Text("这里的内容会在 7 天后自动删除")
                        .font(FocusPetTheme.Typography.subheadline)
                        .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                }
            } else {
                SoftPanel {
                    Text("已删除")
                        .font(FocusPetTheme.Typography.headline)
                        .foregroundStyle(FocusPetTheme.Palette.ink)

                    ForEach(store.deletedTasks) { task in
                        SoftListItem {
                            Text(task.title)
                                .font(FocusPetTheme.Typography.body)
                                .foregroundStyle(FocusPetTheme.Palette.ink)

                            if let notesPreview = task.notesPreview {
                                Text(notesPreview)
                                    .font(FocusPetTheme.Typography.caption)
                                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                                    .lineLimit(2)
                            }

                            Text(task.deletedAtText)
                                .font(FocusPetTheme.Typography.caption)
                                .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("彻底删除", role: .destructive) {
                                pendingPermanentDeleteTask = task
                            }

                            Button("恢复") {
                                store.restoreTask(id: task.id)
                            }
                            .tint(Color.green.opacity(0.8))
                        }
                        .contextMenu {
                            Button("恢复") {
                                store.restoreTask(id: task.id)
                            }

                            Button("彻底删除", role: .destructive) {
                                pendingPermanentDeleteTask = task
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("最近删除")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.cleanupDeletedTasksIfNeeded()
        }
        .alert("彻底删除这个内容？", isPresented: pendingPermanentDeleteBinding) {
            Button("取消", role: .cancel) {
                pendingPermanentDeleteTask = nil
            }
            Button("彻底删除", role: .destructive) {
                if let task = pendingPermanentDeleteTask {
                    store.permanentlyDeleteTask(id: task.id)
                }
                pendingPermanentDeleteTask = nil
            }
        } message: {
            Text("删除后将无法恢复。")
        }
    }

    private var pendingPermanentDeleteBinding: Binding<Bool> {
        Binding(
            get: { pendingPermanentDeleteTask != nil },
            set: { newValue in
                if !newValue {
                    pendingPermanentDeleteTask = nil
                }
            }
        )
    }
}
