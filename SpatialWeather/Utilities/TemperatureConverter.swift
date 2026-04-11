//
//  TemperatureConverter.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-13.
//
import Foundation

struct TemperatureConverter {
    static func formatTemperature(_ temperature: Double, useCelsius: Bool) -> Int {
        let celsius = temperature
        return Int(round(useCelsius ? celsius : (celsius * 9/5 + 32)))
    }
}

func formatTemperature(_ temperature: Double, useCelsius: Bool) -> Int {
    let celsius = temperature
    return Int(round(useCelsius ? celsius : (celsius * 9/5 + 32)))
}
