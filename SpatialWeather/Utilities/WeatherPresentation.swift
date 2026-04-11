import SwiftUI
import WeatherKit

enum SimplifiedWeatherFamily: String, CaseIterable, Identifiable {
    case clear
    case cloudy
    case rain
    case snow
    case thunderstorm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clear:
            return "Clear"
        case .cloudy:
            return "Cloudy"
        case .rain:
            return "Rain"
        case .snow:
            return "Snow"
        case .thunderstorm:
            return "Storm"
        }
    }

    var accent: Color {
        switch self {
        case .clear:
            return Color(hex: "F9C74F")
        case .cloudy:
            return Color(hex: "BEE3F8")
        case .rain:
            return Color(hex: "72B6FF")
        case .snow:
            return Color(hex: "E0F2FE")
        case .thunderstorm:
            return Color(hex: "C084FC")
        }
    }
}

enum Season: String, CaseIterable, Identifiable {
    case spring
    case summer
    case autumn
    case winter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spring:
            return "Spring"
        case .summer:
            return "Summer"
        case .autumn:
            return "Autumn"
        case .winter:
            return "Winter"
        }
    }

    static func resolve(for date: Date, latitude: Double?) -> Season {
        let month = Calendar.current.component(.month, from: date)
        let northernSeason: Season

        switch month {
        case 3...5:
            northernSeason = .spring
        case 6...8:
            northernSeason = .summer
        case 9...11:
            northernSeason = .autumn
        default:
            northernSeason = .winter
        }

        guard let latitude, latitude < 0 else {
            return northernSeason
        }

        switch northernSeason {
        case .spring:
            return .autumn
        case .summer:
            return .winter
        case .autumn:
            return .spring
        case .winter:
            return .summer
        }
    }

    static func presentationSeason(
        for date: Date,
        latitude: Double?,
        family: SimplifiedWeatherFamily?
    ) -> Season {
        if family == .snow {
            return .winter
        }

        return resolve(for: date, latitude: latitude)
    }
}

struct WeatherTheme {
    let gradient: [Color]
    let overlayTint: Color
    let overlayOpacity: Double
    let vignetteOpacity: Double
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let accent: Color
    let cardFillTop: Color
    let cardFillBottom: Color
    let cardStroke: Color
    let selectedFill: Color
    let floatingChipFill: Color
    /// Sky gradient placed *behind* the Spline scene. Visible once the scene's MTKView
    /// background is cleared to transparent by WeatherSymbol3D.
    let atmosphereColors: [Color]
}

enum WeatherThemeResolver {
    static func resolve(
        family: SimplifiedWeatherFamily,
        season: Season,
        isNighttime: Bool
    ) -> WeatherTheme {
        let seasonalGradient = seasonalGradient(for: season, isNighttime: isNighttime)
        let overlayTint = isNighttime ? Color.black : Color(hex: "0A2540")
        let accent = family.accent

        let cardBaseTop = isNighttime ? Color.white.opacity(0.08) : Color.white.opacity(0.12)
        let cardBaseBottom = isNighttime ? accent.opacity(0.10) : accent.opacity(0.08)

        let atmosphereColors = atmosphereOverlay(for: family, isNighttime: isNighttime)

        return WeatherTheme(
            gradient: seasonalGradient,
            overlayTint: overlayTint,
            overlayOpacity: isNighttime ? 0.14 : 0.06,
            vignetteOpacity: isNighttime ? 0.42 : 0.20,
            primaryText: .white,
            secondaryText: .white.opacity(isNighttime ? 0.90 : 0.96),
            tertiaryText: .white.opacity(isNighttime ? 0.72 : 0.78),
            accent: accent,
            cardFillTop: cardBaseTop,
            cardFillBottom: cardBaseBottom,
            cardStroke: .white.opacity(isNighttime ? 0.16 : 0.22),
            selectedFill: accent.opacity(isNighttime ? 0.24 : 0.18),
            floatingChipFill: .white.opacity(isNighttime ? 0.10 : 0.12),
            atmosphereColors: atmosphereColors
        )
    }

    /// Returns a top-to-bottom gradient that is composited over the Spline scene to correct
    /// Sky background placed behind the Spline scene. These are fully opaque colours
    /// that replace the scene's baked-in sky once WeatherSymbol3D clears the MTKView.
    private static func atmosphereOverlay(
        for family: SimplifiedWeatherFamily,
        isNighttime: Bool
    ) -> [Color] {
        switch (family, isNighttime) {
        case (.clear, false):
            return [Color(hex: "4A90E2"), Color(hex: "90CAF9")]
        case (.clear, true):
            return [Color(hex: "080E1C"), Color(hex: "162240")]
        case (.cloudy, false):
            return [Color(hex: "6B7F92"), Color(hex: "A8B8C8")]
        case (.cloudy, true):
            return [Color(hex: "0E1520"), Color(hex: "1E2C3A")]
        case (.rain, false):
            return [Color(hex: "3A506B"), Color(hex: "5C7A90")]
        case (.rain, true):
            return [Color(hex: "060C14"), Color(hex: "101C28")]
        case (.snow, false):
            return [Color(hex: "A8C8E8"), Color(hex: "DCF0F8")]
        case (.snow, true):
            return [Color(hex: "0A1628"), Color(hex: "162A48")]
        case (.thunderstorm, false):
            return [Color(hex: "1A2430"), Color(hex: "323E4C")]
        case (.thunderstorm, true):
            return [Color(hex: "04060C"), Color(hex: "0C1018")]
        }
    }

    private static func seasonalGradient(for season: Season, isNighttime: Bool) -> [Color] {
        switch (season, isNighttime) {
        case (.spring, false):
            return [Color(hex: "1C5D52"), Color(hex: "2F8F83"), Color(hex: "7BC7B1")]
        case (.spring, true):
            return [Color(hex: "0B1E2E"), Color(hex: "13354A"), Color(hex: "245D66")]
        case (.summer, false):
            return [Color(hex: "0B3C6D"), Color(hex: "1478A6"), Color(hex: "73C8E8")]
        case (.summer, true):
            return [Color(hex: "061A40"), Color(hex: "0A3358"), Color(hex: "165C78")]
        case (.autumn, false):
            return [Color(hex: "5D3A1A"), Color(hex: "9D5C26"), Color(hex: "D79C4B")]
        case (.autumn, true):
            return [Color(hex: "1E1328"), Color(hex: "4A243C"), Color(hex: "734338")]
        case (.winter, false):
            return [Color(hex: "243B55"), Color(hex: "476C8E"), Color(hex: "9FC5E8")]
        case (.winter, true):
            return [Color(hex: "0A1026"), Color(hex: "182449"), Color(hex: "2C4C78")]
        }
    }
}

struct SplineWeatherState: Hashable {
    let weatherIndex: Float
    let timeOfDay: Float
    let season: Float

    init(family: SimplifiedWeatherFamily, season: Season, isNighttime: Bool) {
        self.init(
            weatherIndex: Self.weatherIndex(for: family),
            timeOfDay: isNighttime ? 1 : 0,
            season: season == .winter ? 1 : 0
        )
    }

    init(family: SimplifiedWeatherFamily, isNighttime: Bool) {
        self.init(family: family, season: .summer, isNighttime: isNighttime)
    }

    init(weatherIndex: Float, timeOfDay: Float, season: Float) {
        self.weatherIndex = weatherIndex
        self.timeOfDay = timeOfDay
        self.season = season
    }

    var key: String {
        "\(weatherIndex)-\(timeOfDay)-\(season)"
    }

    var family: SimplifiedWeatherFamily {
        switch Int(weatherIndex.rounded()) {
        case 1:
            return .cloudy
        case 2:
            return .rain
        case 3:
            return .snow
        case 4:
            return .thunderstorm
        default:
            return .clear
        }
    }

    private static func weatherIndex(for family: SimplifiedWeatherFamily) -> Float {
        switch family {
        case .clear:
            return 0
        case .cloudy:
            return 1
        case .rain:
            return 2
        case .snow:
            return 3
        case .thunderstorm:
            return 4
        }
    }
}

enum SplineWeatherSceneName: String, CaseIterable, Identifiable {
    case clear = "clear_optimized"
    case cloudy = "cloudy_optimized"
    case rain = "rainy_optimized"
    case snow = "snowy_optimized"
    case thunderstorm = "thunderstorm_optimized"

    var id: String { rawValue }

    var family: SimplifiedWeatherFamily {
        switch self {
        case .clear:
            return .clear
        case .cloudy:
            return .cloudy
        case .rain:
            return .rain
        case .snow:
            return .snow
        case .thunderstorm:
            return .thunderstorm
        }
    }
}

struct SplineWeatherSceneKey: Hashable, Identifiable {
    let sceneName: SplineWeatherSceneName

    init(family: SimplifiedWeatherFamily) {
        sceneName = SplineWeatherSceneResolver.defaultScene(for: family)
    }

    var id: String { sceneName.rawValue }
}

enum SplineWeatherSceneResolver {
    private static let urls: [SplineWeatherSceneName: URL] = {
        Dictionary(uniqueKeysWithValues: SplineWeatherSceneName.allCases.compactMap { scene in
            guard let url = Bundle.main.url(forResource: scene.rawValue, withExtension: "splineswift") else {
                return nil
            }
            return (scene, url)
        })
    }()
    private static let legacyUnifiedSceneURL = Bundle.main.url(forResource: "weather", withExtension: "splineswift")

    static func defaultScene(for family: SimplifiedWeatherFamily) -> SplineWeatherSceneName {
        switch family {
        case .clear:
            return .clear
        case .cloudy:
            return .cloudy
        case .rain:
            return .rain
        case .snow:
            return .snow
        case .thunderstorm:
            return .thunderstorm
        }
    }

    static func url(for key: SplineWeatherSceneKey) -> URL? {
        urls[key.sceneName] ?? legacyUnifiedSceneURL ?? urls[.clear]
    }
}
