//
//  DailyForecast.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-13.
//
import Foundation
import WeatherKit

struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let highTemperature: Double
    let lowTemperature: Double
    let condition: WeatherKit.WeatherCondition
    let sunrise: Date?
    let sunset: Date?
}
