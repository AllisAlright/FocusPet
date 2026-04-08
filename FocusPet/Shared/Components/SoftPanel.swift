import SwiftUI

struct SoftPanel<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: FocusPetTheme.Spacing.medium) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FocusPetTheme.Spacing.medium)
        .background(
            FocusPetTheme.Palette.panel,
            in: RoundedRectangle(cornerRadius: FocusPetTheme.Radius.medium, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FocusPetTheme.Radius.medium, style: .continuous)
                .stroke(FocusPetTheme.Palette.panelStroke, lineWidth: 1)
        )
        .shadow(color: FocusPetTheme.Shadow.panel, radius: 14, y: 8)
    }
}
