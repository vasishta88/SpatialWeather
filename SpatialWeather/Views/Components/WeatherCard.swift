import SwiftUI

enum WeatherSurfaceStyle: Equatable {
    case liveGlass
    case flatTint
}

struct WeatherCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let theme: WeatherTheme
    let surfaceStyle: WeatherSurfaceStyle
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        theme: WeatherTheme,
        surfaceStyle: WeatherSurfaceStyle = .liveGlass,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.theme = theme
        self.surfaceStyle = surfaceStyle
        self.content = content()
    }

    private var backgroundFill: AnyShapeStyle {
        switch surfaceStyle {
        case .liveGlass:
            AnyShapeStyle(.ultraThinMaterial)
        case .flatTint:
            AnyShapeStyle(theme.overlayTint.opacity(0.26))
        }
    }

    private var shadowColor: Color {
        .black.opacity(surfaceStyle == .liveGlass ? 0.14 : 0.08)
    }

    private var shadowRadius: CGFloat {
        surfaceStyle == .liveGlass ? 18 : 10
    }

    private var shadowYOffset: CGFloat {
        surfaceStyle == .liveGlass ? 10 : 5
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(theme.tertiaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(theme.secondaryText)
                }
            }

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(backgroundFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [theme.cardFillTop, theme.cardFillBottom],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(surfaceStyle == .liveGlass ? 1 : 0.86)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(theme.cardStroke, lineWidth: 1)
                )
        )
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowYOffset)
    }
}
