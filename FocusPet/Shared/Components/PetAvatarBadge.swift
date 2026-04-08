import SwiftUI

struct PetAvatarBadge: View {
    let petType: PetType
    let size: PetSize
    var mood: PetMood = .neutral

    var body: some View {
        ZStack {
            Circle()
                .fill(FocusPetTheme.Palette.cloud.opacity(0.95))

            Circle()
                .stroke(FocusPetTheme.Palette.panelStroke.opacity(0.9), lineWidth: 1)

            Circle()
                .fill(FocusPetTheme.Palette.rain.opacity(0.14))
                .padding(innerInset)

            PetAvatarView(petType: petType, size: size, mood: mood)
        }
        .frame(width: containerDimension, height: containerDimension)
        .shadow(color: FocusPetTheme.Shadow.panel.opacity(0.45), radius: 8, y: 3)
    }

    private var containerDimension: CGFloat {
        switch size {
        case .small:
            return 60
        case .large:
            return 88
        }
    }

    private var innerInset: CGFloat {
        switch size {
        case .small:
            return 7
        case .large:
            return 10
        }
    }
}
