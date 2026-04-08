import SwiftUI

struct FocusPetCompanionHeader: View {
    let petType: PetType
    let eyebrow: String
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            PetAvatarBadge(petType: petType, size: .small)

            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow)
                    .font(FocusPetTheme.Typography.caption)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)

                Text(title)
                    .font(FocusPetTheme.Typography.headline)
                    .foregroundStyle(FocusPetTheme.Palette.ink)
                    .lineLimit(1)

                Text(message)
                    .font(FocusPetTheme.Typography.subheadline)
                    .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [
                    FocusPetTheme.Palette.panel,
                    FocusPetTheme.Palette.cloud.opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: FocusPetTheme.Radius.large, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FocusPetTheme.Radius.large, style: .continuous)
                .stroke(FocusPetTheme.Palette.panelStroke, lineWidth: 1)
        )
        .shadow(color: FocusPetTheme.Shadow.panel, radius: 14, y: 8)
    }
}
