//
//  WeatherCondition.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-13.
//


enum WeatherCondition {
    case clear, cloudy, rain, snow, thunderstorm
    
    var description: String {
        switch self {
        case .clear: return "Clear"
        case .cloudy: return "Cloudy"
        case .rain: return "Rain"
        case .snow: return "Snow"
        case .thunderstorm: return "Thunderstorm"
        }
    }
    
    var weatherIcon: String {
        switch self {
        case .clear:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .rain:
            return "cloud.rain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .thunderstorm:
            return "cloud.bolt.fill"
        }
    }
}
