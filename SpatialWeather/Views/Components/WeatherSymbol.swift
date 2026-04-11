//
//  WeatherSymbol.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-14.
//
import SwiftUI
import WeatherKit

struct WeatherSymbol: View {
    let icon: String
    let condition: WeatherKit.WeatherCondition
    var width: CGFloat?
    var height: CGFloat?
    let use3D: Bool
    let isNighttime: Bool
    let season: Season
    
    init(icon: String, condition: WeatherKit.WeatherCondition, width: CGFloat? = nil, height: CGFloat? = nil, use3D: Bool = false, isNighttime: Bool = false, season: Season = .summer) {
        self.icon = icon
        self.condition = condition
        self.width = width
        self.height = height
        self.use3D = use3D
        self.isNighttime = isNighttime
        self.season = season
    }
    
    var body: some View {
        if use3D {
            WeatherSymbol3D(
                splineState: SplineWeatherState(
                    family: condition.simplifiedFamily,
                    season: season,
                    isNighttime: isNighttime
                ),
                scenePlaybackMode: .active
            )
            .frame(maxWidth: width, maxHeight: height)
        } else {
            Image(systemName: icon)
                .font(.system(size: width ?? 30))
                .foregroundColor(.white)
                .frame(width: width, height: height)
        }
    }
}
