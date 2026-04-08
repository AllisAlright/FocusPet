import SwiftUI

enum FocusCompletionAction {
    case continueRound(didAdvance: Bool)
    case rest(didAdvance: Bool)
}

struct FocusCompletionView: View {
    let session: FocusSession
    let task: TaskItem?
    let onComplete: (FocusCompletionAction) -> Void

    @State private var selectedAdvance: Bool?

    var body: some View {
        FocusPetSceneScaffold(title: nil, subtitle: nil) {
            SoftPanel {
                HStack(spacing: 16) {
                    PetAvatarBadge(petType: session.petType, size: .large)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("这一轮结束了")
                            .font(FocusPetTheme.Typography.title)
                            .foregroundStyle(FocusPetTheme.Palette.ink)

                        Text(feedbackText)
                            .font(FocusPetTheme.Typography.subheadline)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            SoftPanel {
                Text(task?.title ?? "自由专注")
                    .font(FocusPetTheme.Typography.headline)
                    .foregroundStyle(FocusPetTheme.Palette.ink)

                Text(session.durationText)
                    .font(FocusPetTheme.Typography.timer)
                    .monospacedDigit()
                    .foregroundStyle(FocusPetTheme.Palette.ink)

                Text("已经专注了这么一会儿。")
                    .font(FocusPetTheme.Typography.subheadline)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
            }

            if task != nil {
                SoftPanel {
                    Text("是否推进了一点？")
                        .font(FocusPetTheme.Typography.headline)
                        .foregroundStyle(FocusPetTheme.Palette.ink)

                    Button {
                        selectedAdvance = true
                    } label: {
                        optionCard(
                            title: "推进了一点",
                            subtitle: "这次会保留投入时间，也记下一点进展。",
                            selected: selectedAdvance == true
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        selectedAdvance = false
                    } label: {
                        optionCard(
                            title: "还没推进",
                            subtitle: "这次先记下投入时间，也没关系。",
                            selected: selectedAdvance == false
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            SoftPanel {
                VStack(spacing: 10) {
                    Button {
                        complete(.continueRound(didAdvance: selectedAdvance ?? false))
                    } label: {
                        Text("再来一轮")
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

                    Button {
                        complete(.rest(didAdvance: selectedAdvance ?? false))
                    } label: {
                        Text("先休息")
                            .font(FocusPetTheme.Typography.subheadline)
                            .foregroundStyle(FocusPetTheme.Palette.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                                    .fill(Color.white.opacity(0.5))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .disabled(task != nil && selectedAdvance == nil)
                .opacity(task != nil && selectedAdvance == nil ? 0.62 : 1)
            }
        }
        .navigationTitle("专注结束")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(task != nil && selectedAdvance == nil)
    }

    private var feedbackText: String {
        switch session.petType {
        case .rabbit:
            return "你刚刚已经认真待在这里了，很不错。"
        case .cat:
            return "这一小段专心，也算把心收回来了。"
        case .dog:
            return "很好，我们已经一起往前动了一下。"
        case .hamster:
            return "又滚过一小格啦，已经有进展了。"
        }
    }

    private func optionCard(title: String, subtitle: String, selected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(selected ? FocusPetTheme.Palette.sage : FocusPetTheme.Palette.inkSoft)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FocusPetTheme.Typography.headline)
                    .foregroundStyle(FocusPetTheme.Palette.ink)

                Text(subtitle)
                    .font(FocusPetTheme.Typography.caption)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                .fill(selected ? Color.white.opacity(0.72) : Color.white.opacity(0.46))
        )
        .overlay(
            RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                .stroke(Color.white.opacity(selected ? 0.88 : 0.32), lineWidth: 1)
        )
    }

    private func complete(_ action: FocusCompletionAction) {
        onComplete(action)
    }
}
