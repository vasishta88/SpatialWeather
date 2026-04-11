//
//  HourlyForecast.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-13.
//
import Foundation
import WeatherKit


struct HourlyForecast: Identifiable {
    var id: Date { date }
    let date: Date
    let temperature: Double
    let feelsLike: Double
    let precipitationChance: Double
    let condition: WeatherKit.WeatherCondition
}
