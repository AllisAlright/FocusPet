import SwiftUI

struct UndoToastView: View {
    let title: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(FocusPetTheme.Typography.headline)
                .foregroundStyle(FocusPetTheme.Palette.ink)

            Spacer(minLength: 0)

            Button(actionTitle, action: action)
                .font(FocusPetTheme.Typography.subheadline)
                .foregroundStyle(FocusPetTheme.Palette.sage)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: FocusPetTheme.Radius.medium, style: .continuous)
                .fill(Color.white.opacity(0.86))
        )
        .overlay(
            RoundedRectangle(cornerRadius: FocusPetTheme.Radius.medium, style: .continuous)
                .stroke(Color.white.opacity(0.92), lineWidth: 1)
        )
        .shadow(color: FocusPetTheme.Shadow.panel, radius: 14, y: 8)
    }
}
