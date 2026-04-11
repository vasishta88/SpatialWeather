import WeatherKit

extension Wind.CompassDirection {
    var abbreviation: String {
        switch self {
        case .north:          return "N"
        case .northNortheast: return "NNE"
        case .northeast:      return "NE"
        case .eastNortheast:  return "ENE"
        case .east:           return "E"
        case .eastSoutheast:  return "ESE"
        case .southeast:      return "SE"
        case .southSoutheast: return "SSE"
        case .south:          return "S"
        case .southSouthwest: return "SSW"
        case .southwest:      return "SW"
        case .westSouthwest:  return "WSW"
        case .west:           return "W"
        case .westNorthwest:  return "WNW"
        case .northwest:      return "NW"
        case .northNorthwest: return "NNW"
        @unknown default:     return "—"
        }
    }
}

extension WeatherKit.WeatherCondition {
    func systemIcon(isNighttime: Bool) -> String {
        switch self {
        case .clear, .mostlyClear, .hot:
            return isNighttime ? "moon.stars.fill" : "sun.max.fill"
        case .partlyCloudy:
            return isNighttime ? "cloud.moon.fill" : "cloud.sun.fill"
        case .cloudy, .mostlyCloudy:
            return "cloud.fill"
        case .breezy, .windy:
            return "wind"
        case .sunShowers:
            return isNighttime ? "cloud.moon.rain.fill" : "cloud.sun.rain.fill"
        case .drizzle, .rain, .heavyRain:
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
        @unknown default:
            return "cloud.fill"
        }
    }

    var simplifiedFamily: SimplifiedWeatherFamily {
        switch self {
        case .clear, .mostlyClear, .hot:
            return .clear
        case .cloudy, .mostlyCloudy, .partlyCloudy, .breezy, .windy,
             .blowingDust, .foggy, .haze, .smoky:
            return .cloudy
        case .drizzle, .rain, .heavyRain, .sunShowers, .freezingDrizzle,
             .freezingRain, .hurricane, .tropicalStorm, .hail:
            return .rain
        case .snow, .heavySnow, .blizzard, .blowingSnow, .frigid,
             .flurries, .sunFlurries, .sleet, .wintryMix:
            return .snow
        case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms:
            return .thunderstorm
        @unknown default:
            return .cloudy
        }
    }

    var systemIcon: String {
        systemIcon(isNighttime: false)
    }

    var displayName: String {
        switch self.simplifiedFamily {
        case .clear:
            return "Clear"
        case .cloudy:
            return "Cloudy"
        case .rain:
            return "Rain"
        case .snow:
            return "Snow"
        case .thunderstorm:
            return "Thunderstorm"
        }
    }
}
