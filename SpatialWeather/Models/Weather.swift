//
//  Weather.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-13.
//
import Foundation
import WeatherKit

struct Weather {
    let temperature: Double
    let feelsLike: Double
    let highTemperature: Double
    let lowTemperature: Double
    let condition: WeatherKit.WeatherCondition
    let humidity: Double
    let windSpeed: Double
    let windDirection: String
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
