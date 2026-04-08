import SwiftUI

enum PetMood: Equatable {
    case neutral
    case happy
    case blink
    case cute
}

struct PetCharacterView: View {
    let petType: PetType
    var mood: PetMood = .neutral
    @State private var isBreathing = false
    @State private var isBlinking = false

    var body: some View {
        ZStack {
            shadow
            bodyShape
            headShape
            ears
            cheeks
            face
        }
        .frame(width: 230, height: 240)
        .scaleEffect(baseScale, anchor: .center)
        .offset(y: baseYOffset)
        .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: isBreathing)
        .animation(.spring(response: 0.34, dampingFraction: 0.72), value: mood)
        .animation(.easeInOut(duration: 0.12), value: isBlinking)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
            scheduleBlink()
        }
    }

    private var palette: PetPalette {
        switch petType {
        case .rabbit:
            .init(base: Color(red: 0.98, green: 0.95, blue: 0.93), accent: Color(red: 0.97, green: 0.85, blue: 0.87), body: Color(red: 0.95, green: 0.90, blue: 0.86))
        case .cat:
            .init(base: Color(red: 0.92, green: 0.93, blue: 0.95), accent: Color(red: 0.74, green: 0.77, blue: 0.84), body: Color(red: 0.83, green: 0.85, blue: 0.88))
        case .dog:
            .init(base: Color(red: 0.99, green: 0.93, blue: 0.83), accent: Color(red: 0.90, green: 0.70, blue: 0.52), body: Color(red: 0.95, green: 0.84, blue: 0.66))
        case .hamster:
            .init(base: Color(red: 0.98, green: 0.90, blue: 0.76), accent: Color(red: 0.82, green: 0.64, blue: 0.48), body: Color(red: 0.88, green: 0.74, blue: 0.58))
        }
    }

    private var shadow: some View {
        Ellipse()
            .fill(Color.black.opacity(0.06))
            .frame(width: 132, height: 26)
            .blur(radius: 10)
            .scaleEffect(isBreathing ? 0.97 : 1.01, anchor: .center)
            .offset(y: 94)
    }

    private var bodyShape: some View {
        RoundedRectangle(cornerRadius: 48, style: .continuous)
            .fill(palette.body)
            .frame(width: 124, height: 112)
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 78, height: 34)
                    .offset(y: -8)
            }
            .offset(y: 50)
    }

    private var headShape: some View {
        Circle()
            .fill(palette.base)
            .frame(width: 144, height: 138)
            .overlay(alignment: .bottom) {
                Capsule()
                    .fill(Color.white.opacity(0.20))
                    .frame(width: 66, height: 20)
                    .offset(y: -16)
            }
    }

    @ViewBuilder
    private var ears: some View {
        switch petType {
        case .rabbit:
            HStack(spacing: 26) {
                uprightEar(rotation: -10, wiggle: -earWiggleDegrees)
                uprightEar(rotation: 10, wiggle: earWiggleDegrees)
            }
            .offset(y: -62)
        case .cat:
            HStack(spacing: 48) {
                pointedEar(rotation: -8, wiggle: -earWiggleDegrees * 0.7)
                pointedEar(rotation: 8, wiggle: earWiggleDegrees * 0.7)
            }
            .offset(y: -34)
        case .dog:
            HStack(spacing: 88) {
                floppyEar(rotation: 26, wiggle: earWiggleDegrees * 0.45)
                floppyEar(rotation: -26, wiggle: -earWiggleDegrees * 0.45)
            }
            .offset(y: -2)
        case .hamster:
            HStack(spacing: 82) {
                roundEar(wiggle: -earWiggleDegrees * 0.35).scaleEffect(0.92)
                roundEar(wiggle: earWiggleDegrees * 0.35).scaleEffect(0.92)
            }
            .offset(y: -32)
        }
    }

    private var cheeks: some View {
        HStack(spacing: 56) {
            Circle()
                .fill(Color(red: 0.98, green: 0.82, blue: 0.83).opacity(blushOpacity))
                .frame(width: 18, height: 18)
            Circle()
                .fill(Color(red: 0.98, green: 0.82, blue: 0.83).opacity(blushOpacity))
                .frame(width: 18, height: 18)
        }
        .scaleEffect(blushScale)
        .offset(y: 28)
    }

    private var face: some View {
        ZStack {
            HStack(spacing: 34) {
                eyeView
                eyeView
            }
            .offset(y: 2)

            RoundedTriangle()
                .fill(Color(red: 0.92, green: 0.67, blue: 0.69))
                .frame(width: 12, height: 10)
                .rotationEffect(.degrees(180))
                .offset(y: 24)

            VStack(spacing: 2) {
                Capsule()
                    .fill(FocusPetTheme.Palette.ink)
                    .frame(width: 2, height: 7)
                Capsule()
                    .fill(FocusPetTheme.Palette.ink)
                    .frame(width: mouthWidth, height: mouthHeight)
            }
            .offset(y: 34)
        }
    }

    private var baseScale: CGFloat {
        let breathing: CGFloat = isBreathing ? 1.006 : 0.994
        switch mood {
        case .happy:
            return breathing * reactionBodyScale
        case .blink:
            return breathing * 0.998
        case .cute:
            return breathing * reactionBodyScale
        case .neutral:
            return breathing
        }
    }

    private var baseYOffset: CGFloat {
        let breathing: CGFloat = isBreathing ? -1.6 : 1.2
        switch mood {
        case .happy:
            return breathing - reactionYOffset
        case .blink:
            return breathing - 0.4
        case .cute:
            return breathing - reactionYOffset * 0.75
        case .neutral:
            return breathing
        }
    }

    private var eyeHeight: CGFloat {
        CGFloat(8)
    }

    @ViewBuilder
    private var eyeView: some View {
        if isBlinking {
            Capsule()
                .fill(FocusPetTheme.Palette.ink)
                .frame(width: 10, height: 2.4)
        } else {
            Circle()
                .fill(FocusPetTheme.Palette.ink)
                .frame(width: 8, height: eyeHeight)
        }
    }

    private var mouthWidth: CGFloat {
        switch mood {
        case .happy:
            return dogLike ? CGFloat(24) : CGFloat(21)
        case .cute:
            return hamsterLike ? CGFloat(21) : CGFloat(19)
        case .blink, .neutral:
            return catLike ? CGFloat(16) : CGFloat(18)
        }
    }

    private var mouthHeight: CGFloat {
        switch mood {
        case .happy, .cute:
            return dogLike ? CGFloat(5) : CGFloat(4)
        case .blink, .neutral:
            return CGFloat(3)
        }
    }

    private var blushOpacity: Double {
        switch mood {
        case .happy:
            return dogLike ? 0.70 : 0.64
        case .cute:
            return hamsterLike ? 0.78 : 0.70
        case .blink, .neutral:
            return 0.55
        }
    }

    private var blushScale: CGFloat {
        switch mood {
        case .happy:
            return dogLike ? 1.08 : 1.04
        case .cute:
            return hamsterLike ? 1.12 : 1.07
        case .blink, .neutral:
            return 1.0
        }
    }

    private var earWiggleDegrees: Double {
        switch mood {
        case .happy:
            return dogLike ? -3.6 : -2.4
        case .cute:
            return rabbitLike ? 4.5 : 3.2
        case .blink, .neutral:
            return 0
        }
    }

    private var reactionBodyScale: CGFloat {
        switch petType {
        case .rabbit:
            return 1.001
        case .cat:
            return 1.0
        case .dog:
            return 1.006
        case .hamster:
            return 1.004
        }
    }

    private var reactionYOffset: CGFloat {
        switch petType {
        case .rabbit:
            return 1.2
        case .cat:
            return 0.6
        case .dog:
            return 1.6
        case .hamster:
            return 1.4
        }
    }

    private var rabbitLike: Bool {
        petType == .rabbit
    }

    private var catLike: Bool {
        petType == .cat
    }

    private var dogLike: Bool {
        petType == .dog
    }

    private var hamsterLike: Bool {
        petType == .hamster
    }

    private func scheduleBlink() {
        _Concurrency.Task {
            while true {
                let delay = UInt64.random(in: 4_800_000_000 ... 8_200_000_000)
                try? await _Concurrency.Task.sleep(nanoseconds: delay)
                await MainActor.run {
                    isBlinking = true
                }
                try? await _Concurrency.Task.sleep(nanoseconds: 140_000_000)
                await MainActor.run {
                    isBlinking = false
                }
            }
        }
    }

    private func uprightEar(rotation: Double, wiggle: Double) -> some View {
        ZStack {
            Capsule()
                .fill(palette.base)
                .frame(width: 30, height: 88)
            Capsule()
                .fill(palette.accent)
                .frame(width: 14, height: 60)
        }
        .rotationEffect(.degrees(rotation + wiggle), anchor: .bottom)
    }

    private func pointedEar(rotation: Double, wiggle: Double) -> some View {
        ZStack {
            RoundedTriangle()
                .fill(palette.body)
                .frame(width: 34, height: 42)
            RoundedTriangle()
                .fill(palette.accent)
                .frame(width: 18, height: 22)
                .offset(y: 5)
        }
        .rotationEffect(.degrees(rotation + wiggle), anchor: .bottom)
    }

    private func floppyEar(rotation: Double, wiggle: Double) -> some View {
        Capsule()
            .fill(palette.accent)
            .frame(width: 34, height: 80)
            .rotationEffect(.degrees(rotation + wiggle), anchor: .top)
    }

    private func roundEar(wiggle: Double) -> some View {
        Circle()
            .fill(palette.accent)
            .frame(width: 30, height: 30)
            .overlay {
                Circle()
                    .fill(palette.base.opacity(0.5))
                    .frame(width: 14, height: 14)
            }
            .rotationEffect(.degrees(wiggle), anchor: .bottom)
    }
}

private struct PetPalette {
    let base: Color
    let accent: Color
    let body: Color
}

private struct RoundedTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.maxX - 2, y: rect.minY + 8))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.maxY - 8))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX + 2, y: rect.minY + 8))
        return path
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            PetCharacterView(petType: .rabbit)
            PetCharacterView(petType: .cat)
        }
        HStack {
            PetCharacterView(petType: .dog)
            PetCharacterView(petType: .hamster)
        }
    }
    .padding()
    .background(FocusPetTheme.Palette.mist)
}
