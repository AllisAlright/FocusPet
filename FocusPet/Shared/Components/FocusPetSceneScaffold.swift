import SwiftUI

struct FocusPetSceneScaffold<Content: View>: View {
    let title: String?
    let subtitle: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 370

            ZStack {
                LinearGradient(
                    colors: [
                        FocusPetTheme.Palette.mist,
                        FocusPetTheme.Palette.rain.opacity(0.85),
                        FocusPetTheme.Palette.warm.opacity(0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(FocusPetTheme.Palette.cloud.opacity(0.56))
                    .frame(width: 240, height: 240)
                    .blur(radius: 20)
                    .offset(x: -120, y: -260)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: compact ? 8 : 10) {
                        if title != nil || subtitle != nil {
                            VStack(alignment: .leading, spacing: 2) {
                                if let title {
                                    Text(title)
                                        .font(compact ? FocusPetTheme.Typography.headline : FocusPetTheme.Typography.title)
                                        .foregroundStyle(FocusPetTheme.Palette.ink)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                if let subtitle {
                                    Text(subtitle)
                                        .font(FocusPetTheme.Typography.subheadline)
                                        .foregroundStyle(FocusPetTheme.Palette.inkSoft)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }

                        content()
                    }
                    .padding(.horizontal, FocusPetTheme.Spacing.large)
                    .padding(.top, 6)
                    .padding(.bottom, FocusPetTheme.Spacing.small)
                }
            }
        }
    }
}
