import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: FocusPetStore

    let taskID: UUID?

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var hasEstimate = false
    @State private var estimatedMinutes = 60
    @State private var spentMinutes = 0
    @State private var manualProgress: Double = 0
    @State private var enableFocus = true
    @State private var preferredPetEnabled = false
    @State private var preferredPet: PetType = .rabbit
    @State private var showDeleteAlert = false

    private var existingTask: TaskItem? {
        guard let taskID else { return nil }
        return store.task(with: taskID)
    }

    private var navigationTitle: String {
        existingTask == nil ? "新建事项" : "编辑事项"
    }

    var body: some View {
        NavigationStack {
            FocusPetSceneScaffold(title: nil, subtitle: nil) {
                SoftPanel {
                    Text("事项")
                        .font(FocusPetTheme.Typography.headline)

                    TextField("这件事想怎么命名？", text: $title)
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
                            .frame(minHeight: 132)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                                    .fill(Color.white.opacity(0.55))
                            )
                    }
                }

                SoftPanel {
                    Text("进度")
                        .font(FocusPetTheme.Typography.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("当前进度")
                            .font(FocusPetTheme.Typography.subheadline)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                        Text("\(Int((manualProgress * 100).rounded()))%")
                            .font(FocusPetTheme.Typography.title)
                            .foregroundStyle(FocusPetTheme.Palette.ink)
                    }

                    Slider(value: $manualProgress, in: 0 ... 1, step: 0.05)
                        .tint(FocusPetTheme.Palette.sage)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("已投入 \(spentMinutes) 分钟")
                            .font(FocusPetTheme.Typography.subheadline)
                            .foregroundStyle(FocusPetTheme.Palette.ink)

                        Text("来自专注记录")
                            .font(FocusPetTheme.Typography.caption)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                    }

                    if let task = existingTask,
                       task.estimatedMinutes != nil {
                        Text("已有预估时长时，专注结束后也会继续累计投入时间。")
                            .font(FocusPetTheme.Typography.caption)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
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

                        Text("\(DateDisplayFormatter.fullChineseDate(from: dueDate)) \(DateDisplayFormatter.chineseTime(from: dueDate))")
                            .font(FocusPetTheme.Typography.caption)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
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

                        Toggle("为这件事指定陪伴动物", isOn: $preferredPetEnabled)
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
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                SoftPanel {
                    Text("操作")
                        .font(FocusPetTheme.Typography.headline)

                    if let task = existingTask, enableFocus {
                        if store.canStartFocus(taskID: task.id) {
                            NavigationLink {
                                FocusSetupView(preselectedTaskID: task.id)
                            } label: {
                                Text("开始专注")
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
                        } else {
                            Text("当前状态下不能直接开始专注")
                                .font(FocusPetTheme.Typography.caption)
                                .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                        }
                    }

                    if existingTask != nil {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Text("删除")
                                .font(FocusPetTheme.Typography.body)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }

            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.22), value: enableFocus)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: populateFields)
            .alert("删除这个内容？", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    deleteTask()
                }
            } message: {
                Text("删除后可在「最近删除」中恢复")
            }
        }
    }

    private var isCompletedDraft: Bool {
        draftProgress >= 1
    }

    private func populateFields() {
        guard let task = existingTask else {
            preferredPet = store.settings.defaultPet
            return
        }

        title = task.title
        notes = task.notes
        hasDueDate = task.dueDate != nil
        dueDate = task.dueDate ?? .now
        hasEstimate = task.estimatedMinutes != nil
        estimatedMinutes = task.estimatedMinutes ?? 60
        spentMinutes = task.spentMinutes
        manualProgress = task.manualProgress ?? task.progress
        enableFocus = task.enableFocus
        preferredPetEnabled = task.preferredPet != nil
        preferredPet = task.preferredPet ?? store.settings.defaultPet
    }

    private func saveTask() {
        let normalizedEstimate = hasEstimate ? max(estimatedMinutes, 5) : nil
        let normalizedDueDate = hasDueDate ? dueDate : nil
        let normalizedPet = preferredPetEnabled ? preferredPet : nil
        let normalizedManualProgress = resolvedManualProgress(estimatedMinutes: normalizedEstimate)

        if let task = existingTask {
            store.updateTask(
                id: task.id,
                title: title,
                notes: notes,
                dueDate: normalizedDueDate,
                estimatedMinutes: normalizedEstimate,
                spentMinutes: spentMinutes,
                manualProgress: normalizedManualProgress,
                enableFocus: enableFocus,
                preferredPet: normalizedPet,
                status: isCompletedDraft ? .completed : task.resolvedStatus()
            )
        } else {
            _ = store.createTask(
                title: title,
                notes: notes,
                dueDate: normalizedDueDate,
                estimatedMinutes: normalizedEstimate,
                spentMinutes: spentMinutes,
                manualProgress: normalizedManualProgress,
                enableFocus: enableFocus,
                preferredPet: normalizedPet,
                status: isCompletedDraft ? .completed : .active
            )
        }

        dismiss()
    }

    private func deleteTask() {
        guard let taskID else { return }
        store.softDeleteTask(id: taskID)
        dismiss()
    }

    private func resolvedManualProgress(estimatedMinutes: Int?) -> Double? {
        guard estimatedMinutes == nil else {
            let autoProgress = Double(spentMinutes) / Double(max(estimatedMinutes ?? 1, 1))
            if abs(manualProgress - autoProgress.clamped(to: 0 ... 1)) < 0.0001 {
                return nil
            }
            return manualProgress
        }

        return manualProgress
    }

    private var draftProgress: Double {
        let normalizedEstimate = hasEstimate ? max(estimatedMinutes, 5) : nil
        if let manual = resolvedManualProgress(estimatedMinutes: normalizedEstimate) {
            return manual
        }
        guard let normalizedEstimate, normalizedEstimate > 0 else { return 0 }
        return (Double(spentMinutes) / Double(normalizedEstimate)).clamped(to: 0 ... 1)
    }
}
