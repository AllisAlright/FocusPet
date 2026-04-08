import SwiftUI

struct MemoRecentlyDeletedView: View {
    @EnvironmentObject private var store: FocusPetStore
    @State private var pendingPermanentDeleteMemo: MemoItem?

    var body: some View {
        FocusPetSceneScaffold(title: nil, subtitle: nil) {
            FocusPetCompanionHeader(
                petType: store.settings.defaultPet,
                eyebrow: "安静回收站",
                title: "最近删除",
                message: "这里的内容会在 7 天后自动删除"
            )

            if store.deletedMemoItems.isEmpty {
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

                    ForEach(store.deletedMemoItems) { memo in
                        SoftListItem {
                            Text(memo.previewText.isEmpty ? "空白备忘" : memo.previewText)
                                .font(FocusPetTheme.Typography.body)
                                .foregroundStyle(FocusPetTheme.Palette.ink)

                            Text(memo.deletedAtText)
                                .font(FocusPetTheme.Typography.caption)
                                .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("彻底删除", role: .destructive) {
                                pendingPermanentDeleteMemo = memo
                            }

                            Button("恢复") {
                                store.restoreMemo(id: memo.id)
                            }
                            .tint(Color.green.opacity(0.8))
                        }
                        .contextMenu {
                            Button("恢复") {
                                store.restoreMemo(id: memo.id)
                            }

                            Button("彻底删除", role: .destructive) {
                                pendingPermanentDeleteMemo = memo
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("最近删除")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.cleanupDeletedMemosIfNeeded()
        }
        .alert("彻底删除这个内容？", isPresented: pendingPermanentDeleteBinding) {
            Button("取消", role: .cancel) {
                pendingPermanentDeleteMemo = nil
            }
            Button("彻底删除", role: .destructive) {
                if let memo = pendingPermanentDeleteMemo {
                    store.permanentlyDeleteMemo(id: memo.id)
                }
                pendingPermanentDeleteMemo = nil
            }
        } message: {
            Text("删除后将无法恢复。")
        }
    }

    private var pendingPermanentDeleteBinding: Binding<Bool> {
        Binding(
            get: { pendingPermanentDeleteMemo != nil },
            set: { newValue in
                if !newValue {
                    pendingPermanentDeleteMemo = nil
                }
            }
        )
    }
}
