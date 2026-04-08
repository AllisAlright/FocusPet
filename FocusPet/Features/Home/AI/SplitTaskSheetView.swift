import SwiftUI

struct SplitTaskSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SplitTaskSheetViewModel

    let preferredPet: PetType
    let onImportSelected: ([String]) -> Void

    // The sheet still owns its own view model.
    // We only swap which provider gets injected, so the UI flow stays the same.
    init(
        preferredPet: PetType,
        provider: any SplitTaskProviding = APISplitTaskProvider(),
        onImportSelected: @escaping ([String]) -> Void
    ) {
        self.preferredPet = preferredPet
        self.onImportSelected = onImportSelected
        _viewModel = StateObject(wrappedValue: SplitTaskSheetViewModel(provider: provider))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: FocusPetTheme.Spacing.medium) {
                    SoftPanel {
                        Text("帮你把目标拆小一点")
                            .font(FocusPetTheme.Typography.title)
                            .foregroundStyle(FocusPetTheme.Palette.ink)

                        Text(helperText)
                            .font(FocusPetTheme.Typography.subheadline)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)

                        VStack(alignment: .leading, spacing: FocusPetTheme.Spacing.small) {
                            Text("想推进什么？")
                                .font(FocusPetTheme.Typography.subheadline)
                                .foregroundStyle(FocusPetTheme.Palette.inkSoft)

                            TextField("比如：准备产品经理面试", text: $viewModel.input, axis: .vertical)
                                .font(FocusPetTheme.Typography.body)
                                .lineLimit(2 ... 4)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                                        .fill(Color.white.opacity(0.55))
                                )
                        }

                        Button {
                            _Concurrency.Task {
                                await viewModel.generateSuggestions()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if viewModel.phase == .loading {
                                    ProgressView()
                                        .tint(FocusPetTheme.Palette.ink)
                                }

                                Text(primaryButtonTitle)
                                    .font(FocusPetTheme.Typography.headline)
                            }
                            .foregroundStyle(FocusPetTheme.Palette.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                                    .fill(FocusPetTheme.Palette.warm.opacity(0.82))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!viewModel.canSubmit)
                        .opacity(viewModel.canSubmit ? 1 : 0.58)
                    }

                    resultContent
                }
                .padding(.horizontal, FocusPetTheme.Spacing.large)
                .padding(.top, FocusPetTheme.Spacing.large)
                .padding(.bottom, FocusPetTheme.Spacing.xxLarge)
            }
            .animation(.easeInOut(duration: 0.22), value: viewModel.phase)
            .scrollDismissesKeyboard(.interactively)
            .background(sheetBackground.ignoresSafeArea())
            .navigationTitle("轻轻拆一下")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var resultContent: some View {
        switch viewModel.phase {
        case .idle:
            EmptyView()

        case .loading:
            SoftPanel {
                HStack(spacing: FocusPetTheme.Spacing.small) {
                    ProgressView()
                        .tint(FocusPetTheme.Palette.ink)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("让我想一想...")
                            .font(FocusPetTheme.Typography.headline)
                            .foregroundStyle(FocusPetTheme.Palette.ink)

                        Text("我在帮你整理几个更容易开始的小步骤。")
                            .font(FocusPetTheme.Typography.subheadline)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                    }
                }
            }

        case let .failed(message):
            SoftPanel {
                Text("这次没有整理出来")
                    .font(FocusPetTheme.Typography.headline)
                    .foregroundStyle(FocusPetTheme.Palette.ink)

                Text(message)
                    .font(FocusPetTheme.Typography.subheadline)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)

                Button("再试一次") {
                    _Concurrency.Task {
                        await viewModel.generateSuggestions()
                    }
                }
                .font(FocusPetTheme.Typography.headline)
                .foregroundStyle(FocusPetTheme.Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                        .fill(Color.white.opacity(0.58))
                )
                .buttonStyle(.plain)
                .disabled(!viewModel.canSubmit)
            }

        case .loaded:
            SoftPanel {
                if let understandingMessage = viewModel.understandingMessage {
                    SoftListItem {
                        Text("我理解你想做的是")
                            .font(FocusPetTheme.Typography.headline)
                            .foregroundStyle(FocusPetTheme.Palette.ink)

                        Text(understandingMessage)
                            .font(FocusPetTheme.Typography.subheadline)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Text("可以先从这些开始")
                    .font(FocusPetTheme.Typography.headline)
                    .foregroundStyle(FocusPetTheme.Palette.ink)

                Text("我先帮你选了一些更关键的步骤，不需要的可以取消。")
                    .font(FocusPetTheme.Typography.subheadline)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)

                VStack(spacing: FocusPetTheme.Spacing.small) {
                    ForEach(viewModel.suggestions) { suggestion in
                        SplitTaskSuggestionRow(suggestion: suggestion) {
                            viewModel.toggleSelection(for: suggestion.id)
                        }
                    }
                }

                Button("导入到待办") {
                    importSelectedSuggestions()
                }
                .font(FocusPetTheme.Typography.headline)
                .foregroundStyle(FocusPetTheme.Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                        .fill(FocusPetTheme.Palette.sage.opacity(0.72))
                )
                .buttonStyle(.plain)
                .disabled(viewModel.selectedSuggestions.isEmpty)
                .opacity(viewModel.selectedSuggestions.isEmpty ? 0.58 : 1)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var helperText: String {
        switch preferredPet {
        case .rabbit:
            return "先告诉我一个还没理清的目标，我会陪你整理成几步。"
        case .cat:
            return "说一个有点模糊的目标，我来帮你理出起点。"
        case .dog:
            return "把想做的事告诉我，我们先拆成几步动起来。"
        case .hamster:
            return "丢给我一个大目标吧，我们先滚出几小步。"
        }
    }

    private var primaryButtonTitle: String {
        switch viewModel.phase {
        case .failed:
            return "再帮我拆一次"
        default:
            return "帮我拆解"
        }
    }

    private var sheetBackground: some View {
        LinearGradient(
            colors: [
                FocusPetTheme.Palette.cloud,
                FocusPetTheme.Palette.rain.opacity(0.88),
                FocusPetTheme.Palette.warm.opacity(0.74)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func importSelectedSuggestions() {
        let selectedTitles = viewModel.selectedSuggestions.map(\.title)
        guard !selectedTitles.isEmpty else { return }

        onImportSelected(selectedTitles)
        viewModel.resetAfterImport()
        dismiss()
    }
}
