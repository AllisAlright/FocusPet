import SwiftUI

struct HomePetSelectionSheet: View {
    let selectedPet: PetType
    let onSelect: (PetType) -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    FocusPetTheme.Palette.mist,
                    FocusPetTheme.Palette.rain.opacity(0.88),
                    FocusPetTheme.Palette.warm.opacity(0.86)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                Text("选择陪你的伙伴")
                    .font(FocusPetTheme.Typography.headline)
                    .foregroundStyle(FocusPetTheme.Palette.ink)

                PetSelectionBar(selectedPet: selectedPet, onSelect: onSelect)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: FocusPetTheme.Radius.medium, style: .continuous)
                        .fill(Color.white.opacity(0.42))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FocusPetTheme.Radius.medium, style: .continuous)
                        .stroke(Color.white.opacity(0.56), lineWidth: 1)
                )
            }
            .padding(.horizontal, FocusPetTheme.Spacing.large)
            .padding(.top, 14)
            .padding(.bottom, 10)
        }
    }
}

#Preview {
    HomePetSelectionSheet(selectedPet: .rabbit) { _ in }
}
