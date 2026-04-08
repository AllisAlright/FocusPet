import SwiftUI

struct TaskArchiveDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: FocusPetStore

    let task: TaskItem

    private var resolvedStatus: TaskStatus {
        task.resolvedStatus()
    }

    private var canReactivate: Bool {
        resolvedStatus == .paused || resolvedStatus == .overdue
    }

    var body: some View {
        FocusPetSceneScaffold(title: nil, subtitle: nil) {
            SoftPanel {
                Text("事项")
                    .font(FocusPetTheme.Typography.subheadline)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)

                Text(task.title)
                    .font(FocusPetTheme.Typography.headline)
                    .foregroundStyle(FocusPetTheme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            SoftPanel {
                Text("备注")
                    .font(FocusPetTheme.Typography.subheadline)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)

                Text(task.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "这里还没有补充备注。" : task.notes)
                    .font(FocusPetTheme.Typography.body)
                    .foregroundStyle(task.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? FocusPetTheme.Palette.inkSoft : FocusPetTheme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            SoftPanel {
                metadataRow(label: "状态", value: resolvedStatus.displayName)

                if resolvedStatus == .completed {
                    metadataRow(
                        label: "完成于",
                        value: DateDisplayFormatter.relativeChineseDateTime(from: task.updatedAt)
                    )
                } else {
                    metadataRow(label: "当前进度", value: task.progressText)
                }

                if task.spentMinutes > 0 {
                    metadataRow(label: "已投入", value: "\(task.spentMinutes) 分钟")
                }
            }
        }
        .navigationTitle("事项记录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                }
            }

            if canReactivate {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("重新激活") {
                        store.reactivateTask(id: task.id)
                        dismiss()
                    }
                    .font(FocusPetTheme.Typography.subheadline)
                }
            }
        }
    }

    private func metadataRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(FocusPetTheme.Typography.subheadline)
                .foregroundStyle(FocusPetTheme.Palette.inkSoft)

            Text(value)
                .font(FocusPetTheme.Typography.body)
                .foregroundStyle(FocusPetTheme.Palette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
