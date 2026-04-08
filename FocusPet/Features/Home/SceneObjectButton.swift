import SwiftUI

struct SceneObjectButton: View {
    enum ObjectStyle {
        case notebook
        case board
        case lampClock
        case archiveBox
    }

    let title: String
    let subtitle: String
    let style: ObjectStyle
    let action: () -> Void

    private var showsSubtitle: Bool {
        !subtitle.isEmpty
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: showsSubtitle ? 10 : 8) {
                objectShape
                    .frame(height: showsSubtitle ? 76 : 82)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(FocusPetTheme.Typography.headline)
                        .foregroundStyle(FocusPetTheme.Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if showsSubtitle {
                        Text(subtitle)
                            .font(FocusPetTheme.Typography.subheadline)
                            .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: showsSubtitle ? 128 : 116, alignment: .topLeading)
            .padding(.horizontal, 12)
            .padding(.vertical, showsSubtitle ? 10 : 12)
            .background(
                RoundedRectangle(cornerRadius: FocusPetTheme.Radius.medium, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                FocusPetTheme.Palette.panel.opacity(0.64),
                                FocusPetTheme.Palette.cloud.opacity(0.42)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: FocusPetTheme.Radius.medium, style: .continuous)
                    .stroke(Color.white.opacity(0.62), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: FocusPetTheme.Radius.medium, style: .continuous))
    }

    @ViewBuilder
    private var objectShape: some View {
        switch style {
        case .notebook:
            NotebookObjectShape()
        case .board:
            BoardObjectShape()
        case .lampClock:
            LampClockObjectShape()
        case .archiveBox:
            ArchiveBoxObjectShape()
        }
    }
}

private struct NotebookObjectShape: View {
    var body: some View {
        ZStack(alignment: .leading) {
            Circle()
                .fill(FocusPetTheme.Palette.peach)
                .frame(width: 60, height: 60)
                .overlay {
                    ZStack {
                        YarnThread()
                            .stroke(Color(red: 0.83, green: 0.62, blue: 0.58), lineWidth: 1.6)
                            .frame(width: 36, height: 36)
                        YarnThread()
                            .stroke(Color(red: 0.89, green: 0.73, blue: 0.66), lineWidth: 1.2)
                            .frame(width: 24, height: 24)
                            .rotationEffect(.degrees(90))
                    }
                }
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                .offset(x: 2, y: 8)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(FocusPetTheme.Palette.warm)
                .frame(width: 54, height: 40)
                .offset(x: 52, y: 18)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(FocusPetTheme.Palette.cloud)
                .frame(width: 64, height: 46)
                .offset(x: 42, y: 10)

            VStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color(red: 0.84, green: 0.77, blue: 0.70))
                        .frame(width: 24, height: 3)
                }
            }
            .offset(x: 52, y: 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BoardObjectShape: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.73, green: 0.82, blue: 0.88))
                .frame(width: 96, height: 58)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.7))
                .frame(width: 62, height: 8)
                .offset(x: 12, y: -12)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.7))
                .frame(width: 44, height: 8)
                .offset(x: 12, y: -26)

            Capsule()
                .fill(Color(red: 0.73, green: 0.66, blue: 0.58))
                .frame(width: 84, height: 10)
                .offset(x: 6, y: 10)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(red: 0.48, green: 0.43, blue: 0.40))
                .frame(width: 20, height: 6)
                .offset(x: 38, y: 17)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LampClockObjectShape: View {
    var body: some View {
        ZStack(alignment: .leading) {
            Circle()
                .fill(FocusPetTheme.Palette.cloud)
                .frame(width: 56, height: 56)
                .overlay {
                    Circle()
                        .stroke(Color(red: 0.88, green: 0.79, blue: 0.62), lineWidth: 4)
                    ClockHands()
                        .stroke(Color(red: 0.66, green: 0.57, blue: 0.47), lineWidth: 2.2)
                        .frame(width: 20, height: 20)
                }

            VStack(spacing: 0) {
                Circle()
                    .fill(Color(red: 0.98, green: 0.88, blue: 0.65))
                    .frame(width: 24, height: 24)
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.75), lineWidth: 2)
                    }

                Capsule()
                    .fill(Color(red: 0.80, green: 0.74, blue: 0.66))
                    .frame(width: 7, height: 24)

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 0.85, green: 0.80, blue: 0.74))
                    .frame(width: 34, height: 8)
            }
            .offset(x: 66, y: 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ArchiveBoxObjectShape: View {
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.87, green: 0.80, blue: 0.71))
                .frame(width: 100, height: 52)
                .offset(y: 10)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.92, green: 0.85, blue: 0.76))
                .frame(width: 108, height: 24)
                .overlay(alignment: .center) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 26, height: 8)
                }
                .offset(y: -10)

            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(red: 0.96, green: 0.90, blue: 0.82))
                    .frame(width: 16, height: 20)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(red: 0.94, green: 0.86, blue: 0.76))
                    .frame(width: 16, height: 20)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(red: 0.90, green: 0.82, blue: 0.73))
                    .frame(width: 16, height: 20)
            }
            .offset(x: 16, y: 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ClockHands: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: center)
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + 2))
        path.move(to: center)
        path.addLine(to: CGPoint(x: rect.maxX - 3, y: rect.midY + 2))
        return path
    }
}

private struct YarnThread: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 2, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY + 4),
            control: CGPoint(x: rect.minX + 10, y: rect.minY + 4)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - 4, y: rect.midY),
            control: CGPoint(x: rect.maxX - 8, y: rect.minY + 8)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY - 4),
            control: CGPoint(x: rect.maxX - 6, y: rect.maxY - 6)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + 6, y: rect.midY + 4),
            control: CGPoint(x: rect.minX + 8, y: rect.maxY - 2)
        )
        return path
    }
}

#Preview {
    SceneObjectButton(
        title: "备忘录",
        subtitle: "小本子",
        style: .notebook,
        action: {}
    )
    .padding()
    .background(Color(red: 0.94, green: 0.96, blue: 0.95))
}
