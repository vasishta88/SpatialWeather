//
//  WeatherSymbol.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-14.
//
import SwiftUI
import RealityKit
import WeatherKit

struct WeatherSymbol: View {
    let icon: String
    let condition: WeatherKit.WeatherCondition
    var width: CGFloat?
    var height: CGFloat?
    let use3D: Bool
    let isNighttime: Bool
    
    init(icon: String, condition: WeatherKit.WeatherCondition, width: CGFloat? = nil, height: CGFloat? = nil, use3D: Bool = false, isNighttime: Bool = false) {
        self.icon = icon
        self.condition = condition
        self.width = width
        self.height = height
        self.use3D = use3D
        self.isNighttime = isNighttime
    }
    
    var body: some View {
        if use3D {
            WeatherSymbol3D(
                condition: condition,
                isNighttime: isNighttime
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
