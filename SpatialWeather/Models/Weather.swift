//
//  Weather.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-13.
//
import Foundation
import SwiftUI
import WeatherKit

struct Weather {
    let temperature: Double
    let feelsLike: Double
    let highTemperature: Double
    let lowTemperature: Double
    let condition: WeatherKit.WeatherCondition
    let humidity: Double
    let windSpeed: Double
    let uvIndex: Int
    let airQualityIndex: Int
    let sunrise: Date?
    let sunset: Date?
    let visibility: Double

    var isNighttime: Bool {
        guard let sunrise = sunrise, let sunset = sunset else { return false }
        let now = Date()
        return now < sunrise || now > sunset
    }
}

// Preview Provider
struct WeatherDetailCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Single card preview
            WeatherDetailCard(
                title: "Humidity",
                value: "65%",
                icon: "humidity.fill"
            )
            .previewLayout(.sizeThatFits)
            .padding()
            
            // Grid preview
            WeatherDetailsGrid(
                weather: Weather(
                    temperature: 25.0,
                    feelsLike: 27.0,
                    highTemperature: 28.0,
                    lowTemperature: 20.0,
                    condition: .clear,
                    humidity: 65.0,
                    windSpeed: 12.0,
                    uvIndex: 5,
                    airQualityIndex: 45,
                    sunrise: Optional(Date()),
                    sunset: Optional(Date().addingTimeInterval(43200)),
                    visibility: 10.0
                ),
                useCelsius: true
            )
            .previewLayout(.sizeThatFits)
            .padding()
        }
    }
}
