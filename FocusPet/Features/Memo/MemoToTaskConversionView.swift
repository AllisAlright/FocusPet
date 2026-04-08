import SwiftUI

struct MemoToTaskConversionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: FocusPetStore

    let memo: MemoItem
    let onComplete: (() -> Void)?

    @State private var title: String
    @State private var notes: String
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var hasEstimate = false
    @State private var estimatedMinutes = 60
    @State private var enableFocus = true
    @State private var preferredPetEnabled = false
    @State private var preferredPet: PetType
    @State private var removeOriginalMemo = false

    init(memo: MemoItem, onComplete: (() -> Void)? = nil) {
        self.memo = memo
        self.onComplete = onComplete
        let trimmed = memo.trimmedContent
        let lines = trimmed
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let firstLine = lines.first ?? trimmed

        _title = State(initialValue: String(firstLine.prefix(24)).trimmingCharacters(in: .whitespacesAndNewlines))
        _notes = State(initialValue: memo.content)
        _preferredPet = State(initialValue: .rabbit)
    }

    var body: some View {
        FocusPetSceneScaffold(title: nil, subtitle: nil) {
            SoftPanel {
                Text("事项")
                    .font(FocusPetTheme.Typography.headline)

                TextField("事项标题", text: $title)
                    .font(FocusPetTheme.Typography.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                            .fill(Color.white.opacity(0.55))
                    )

                VStack(alignment: .leading, spacing: FocusPetTheme.Spacing.small) {
                    Text("备注")
                        .font(FocusPetTheme.Typography.subheadline)
                        .foregroundStyle(FocusPetTheme.Palette.inkSoft)

                    TextEditor(text: $notes)
                        .font(.system(.body, design: .rounded))
                        .frame(minHeight: 150)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                                .fill(Color.white.opacity(0.55))
                        )
                }
            }

            SoftPanel {
                Text("时间")
                    .font(FocusPetTheme.Typography.headline)

                Toggle("设置截止日期", isOn: $hasDueDate)
                    .tint(FocusPetTheme.Palette.sage)

                if hasDueDate {
                    DatePicker("截止时间", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .environment(\.locale, DateDisplayFormatter.zhLocale)
                }

                Toggle("填写预估时长", isOn: $hasEstimate)
                    .tint(FocusPetTheme.Palette.sage)

                if hasEstimate {
                    Stepper(value: $estimatedMinutes, in: 5 ... 600, step: 5) {
                        Text("预估 \(estimatedMinutes) 分钟")
                    }
                }
            }

            SoftPanel {
                Text("专注")
                    .font(FocusPetTheme.Typography.headline)

                Toggle("允许进入专注", isOn: $enableFocus)
                    .tint(FocusPetTheme.Palette.sage)
            }

            if enableFocus {
                SoftPanel {
                    Text("陪伴")
                        .font(FocusPetTheme.Typography.headline)

                    Toggle("指定陪伴动物", isOn: $preferredPetEnabled)
                        .tint(FocusPetTheme.Palette.sage)

                    if preferredPetEnabled {
                        Picker("陪伴动物", selection: $preferredPet) {
                            ForEach(PetType.allCases) { pet in
                                Text(pet.displayName).tag(pet)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }

            SoftPanel {
                Toggle("转换后删除原备忘", isOn: $removeOriginalMemo)
                    .tint(FocusPetTheme.Palette.peach)

                Text(removeOriginalMemo ? "确认后会把原备忘移到最近删除。" : "默认会保留原备忘，方便你之后继续查看。")
                    .font(FocusPetTheme.Typography.caption)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
            }
        }
        .navigationTitle("转为待办")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("确认") {
                    convertMemo()
                }
                .fontWeight(.semibold)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            preferredPet = store.settings.defaultPet
        }
    }

    private func convertMemo() {
        _ = store.convertMemoToTask(
            memoID: memo.id,
            title: title,
            notes: notes,
            dueDate: hasDueDate ? dueDate : nil,
            estimatedMinutes: hasEstimate ? estimatedMinutes : nil,
            enableFocus: enableFocus,
            preferredPet: preferredPetEnabled ? preferredPet : nil,
            deleteOriginalMemo: removeOriginalMemo
        )

        onComplete?()
        dismiss()
    }
}
