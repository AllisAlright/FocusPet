import SwiftUI

struct SplitTaskSuggestionRow: View {
    let suggestion: SplitTaskSuggestion
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: FocusPetTheme.Spacing.small) {
                Image(systemName: suggestion.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(suggestion.isSelected ? FocusPetTheme.Palette.sage : FocusPetTheme.Palette.inkSoft.opacity(0.55))
                    .padding(.top, 1)

                Text(suggestion.title)
                    .font(FocusPetTheme.Typography.body)
                    .foregroundStyle(suggestion.isSelected ? FocusPetTheme.Palette.ink : FocusPetTheme.Palette.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(FocusPetTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: FocusPetTheme.Radius.medium, style: .continuous)
                    .fill(Color.white.opacity(0.58))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FocusPetTheme.Radius.medium, style: .continuous)
                    .stroke(Color.white.opacity(0.78), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
