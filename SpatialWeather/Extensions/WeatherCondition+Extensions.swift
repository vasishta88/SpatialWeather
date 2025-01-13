import WeatherKit

extension WeatherKit.WeatherCondition {
    var systemIcon: String {
        switch self {
        case .clear, .mostlyClear, .hot:
            return "sun.max.fill"
        case .cloudy, .mostlyCloudy, .partlyCloudy:
            return "cloud.fill"
        case .breezy, .windy:
            return "wind"
        case .drizzle, .rain, .heavyRain, .sunShowers:
            return "cloud.rain.fill"
        case .snow, .heavySnow, .flurries, .sunFlurries:
            return "cloud.snow.fill"
        case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms:
            return "cloud.bolt.fill"
        case .blizzard, .blowingSnow:
            return "wind.snow"
        case .sleet, .wintryMix, .freezingDrizzle, .freezingRain:
            return "cloud.sleet.fill"
        case .foggy, .haze:
            return "cloud.fog.fill"
        case .smoky:
            return "smoke.fill"
        case .frigid:
            return "thermometer.snowflake"
        case .hurricane, .tropicalStorm:
            return "hurricane"
        case .blowingDust:
            return "dust"
        case .hail:
            return "cloud.hail.fill"
        }
    }
} 