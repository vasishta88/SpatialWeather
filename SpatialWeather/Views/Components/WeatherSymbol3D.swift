//
//  WeatherSymbol3D.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-14.
//


import SwiftUI
import SplineRuntime
import WeatherKit

struct WeatherSymbol3D: View {
    let condition: WeatherKit.WeatherCondition
    let isNighttime: Bool
    
    private func convertToSimplifiedCondition(_ condition: WeatherKit.WeatherCondition) -> WeatherCondition {
        switch condition {
            // Clear conditions
            case .clear, .mostlyClear, .hot:
                return .clear
            
            // Cloudy conditions
            case .cloudy, .mostlyCloudy, .partlyCloudy, .breezy, .windy,
                 .blowingDust, .foggy, .haze, .smoky:
                return .cloudy
            
            // Rain conditions
            case .drizzle, .rain, .heavyRain, .sunShowers, .freezingDrizzle,
                 .freezingRain, .hurricane, .tropicalStorm, .hail:
                return .rain
            
            // Snow conditions
            case .snow, .heavySnow, .blizzard, .blowingSnow, .frigid,
                 .flurries, .sunFlurries, .sleet, .wintryMix:
                return .snow
            
            // Thunderstorm conditions
            case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms,
                 .strongStorms:
                return .thunderstorm
        }
    }
    
    private func getSplineURL() -> URL {
        let simplifiedCondition = convertToSimplifiedCondition(condition)
        let fileName = switch simplifiedCondition {
            case .clear: 
                isNighttime ? "clear_night" : "clear_day"
            case .cloudy:
                isNighttime ? "cloudy_night" : "cloudy_day"
            case .rain:
                isNighttime ? "rain_night" : "rain_day"
            case .thunderstorm:
                isNighttime ? "thunderstorm_night" : "thunderstorm_day"
            case .snow:
                isNighttime ? "snow_night" : "snow_day"
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "splineswift") else {
            print("Error: Could not find spline file: \(fileName).splineswift")
            return Bundle.main.url(forResource: "clear_day", withExtension: "splineswift")!
        }
        
        return url
    }
    
    var body: some View {
        SplineView(sceneFileURL: getSplineURL())
            .id("\(condition)-\(isNighttime)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
    }
}
