import SwiftUI

struct SoftFeedbackToast: View {
    let title: String

    var body: some View {
        Text(title)
            .font(FocusPetTheme.Typography.headline)
            .foregroundStyle(FocusPetTheme.Palette.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: FocusPetTheme.Radius.medium, style: .continuous)
                    .fill(Color.white.opacity(0.88))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FocusPetTheme.Radius.medium, style: .continuous)
                    .stroke(Color.white.opacity(0.96), lineWidth: 1)
            )
            .shadow(color: FocusPetTheme.Shadow.panel, radius: 14, y: 8)
    }
}
