import SwiftUI

struct PetSelectionBar: View {
    let selectedPet: PetType
    let onSelect: (PetType) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(PetType.allCases) { pet in
                let isSelected = selectedPet == pet
                Button {
                    onSelect(pet)
                } label: {
                    VStack(spacing: 5) {
                        PetCharacterView(petType: pet)
                            .frame(width: 58, height: 58)
                            .scaleEffect(isSelected ? 0.28 : 0.25)
                            .padding(.top, 2)

                        Text(pet.displayName)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(isSelected ? FocusPetTheme.Palette.ink : FocusPetTheme.Palette.inkSoft)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text(isSelected ? "陪你中" : "选择")
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundStyle(isSelected ? FocusPetTheme.Palette.inkSoft : FocusPetTheme.Palette.inkSoft.opacity(0.72))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 102)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                isSelected
                                    ? LinearGradient(
                                        colors: [
                                            FocusPetTheme.Palette.panel,
                                            FocusPetTheme.Palette.warm.opacity(0.54)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    : LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.48),
                                            Color.white.opacity(0.30)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isSelected ? Color.white.opacity(0.88) : Color.white.opacity(0.36), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity)
    }
}
