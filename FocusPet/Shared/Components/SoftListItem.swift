import SwiftUI

struct SoftListItem<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: FocusPetTheme.Spacing.small) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FocusPetTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                .fill(Color.white.opacity(0.52))
        )
        .overlay(
            RoundedRectangle(cornerRadius: FocusPetTheme.Radius.small, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        )
    }
}
