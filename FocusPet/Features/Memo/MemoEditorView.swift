import SwiftUI

struct MemoEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: FocusPetStore

    let title: String
    let memo: MemoItem?
    let initialContent: String
    let initialPinned: Bool
    let onSave: (String, Bool) -> Void
    let onDelete: (() -> Void)?

    @State private var content: String
    @State private var isPinned: Bool
    @State private var showDeleteAlert = false
    @State private var showConversionFlow = false

    init(
        title: String,
        memo: MemoItem? = nil,
        initialContent: String,
        initialPinned: Bool,
        onSave: @escaping (String, Bool) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.title = title
        self.memo = memo
        self.initialContent = initialContent
        self.initialPinned = initialPinned
        self.onSave = onSave
        self.onDelete = onDelete
        _content = State(initialValue: initialContent)
        _isPinned = State(initialValue: initialPinned)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        FocusPetTheme.Palette.mist,
                        FocusPetTheme.Palette.rain.opacity(0.85),
                        FocusPetTheme.Palette.warm.opacity(0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    SoftPanel {
                        VStack(spacing: FocusPetTheme.Spacing.small) {
                            Toggle(isOn: $isPinned) {
                                Label("置顶这条备忘", systemImage: isPinned ? "pin.fill" : "pin")
                                    .font(FocusPetTheme.Typography.subheadline)
                                    .foregroundStyle(FocusPetTheme.Palette.ink)
                            }
                            .tint(FocusPetTheme.Palette.peach)

                            if let memo {
                                HStack {
                                    Text(memo.editorUpdatedAtText)
                                        .font(FocusPetTheme.Typography.caption)
                                        .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                                    Spacer(minLength: 0)
                                }
                            }

                            if memo != nil {
                                Button {
                                    showConversionFlow = true
                                } label: {
                                    HStack {
                                        Label("加入待办", systemImage: "arrow.turn.down.right")
                                            .font(FocusPetTheme.Typography.subheadline)
                                            .foregroundStyle(FocusPetTheme.Palette.ink)

                                        Spacer(minLength: 0)

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                                    }
                                    .padding(.top, 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    SoftPanel {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $content)
                                .scrollContentBackground(.hidden)
                                .font(FocusPetTheme.Typography.body)
                                .foregroundStyle(FocusPetTheme.Palette.ink)
                                .frame(minHeight: 260)

                            if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("写点什么吧")
                                    .font(FocusPetTheme.Typography.body)
                                    .foregroundStyle(FocusPetTheme.Palette.inkSoft.opacity(0.8))
                                    .padding(.top, 8)
                                    .padding(.leading, 6)
                                    .allowsHitTesting(false)
                            }
                        }
                    }

                    if onDelete != nil {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Text("删除这条备忘")
                                .font(FocusPetTheme.Typography.subheadline)
                                .foregroundStyle(Color.red.opacity(0.82))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                                        .fill(Color.white.opacity(0.40))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                                        .stroke(Color.white.opacity(0.48), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, FocusPetTheme.Spacing.large)
                .padding(.top, 10)
                .padding(.bottom, 12)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showConversionFlow) {
                if let memo {
                    MemoToTaskConversionView(memo: memo) {
                        dismiss()
                    }
                    .environmentObject(store)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        onSave(content, isPinned)
                        dismiss()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("删除这个内容？", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) {}
                if let onDelete {
                    Button("删除", role: .destructive) {
                        onDelete()
                        dismiss()
                    }
                }
            } message: {
                Text("删除后可在「最近删除」中恢复")
            }
        }
    }
}
