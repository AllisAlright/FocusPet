import SwiftUI

enum PetSize {
    case small
    case large
}

struct PetAvatarView: View {
    let petType: PetType
    let size: PetSize
    var mood: PetMood = .neutral
    var soften = true

    var body: some View {
        PetCharacterView(petType: petType, mood: mood)
            .scaleEffect(scale)
            .frame(width: dimension, height: dimension)
            .opacity(soften ? 0.94 : 1)
    }

    private var dimension: CGFloat {
        switch size {
        case .small:
            return 44
        case .large:
            return 72
        }
    }

    // PetCharacterView base canvas height is 240pt.
    private var scale: CGFloat {
        dimension / 240
    }
}
