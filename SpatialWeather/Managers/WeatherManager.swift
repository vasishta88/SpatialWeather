//
//  WeatherManager.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-13.
//


import WeatherKit
import SwiftUI
import CoreLocation
import Foundation


// Weather Manager
class WeatherManager: ObservableObject {
    @Published var currentWeather: Weather?
    @Published var hourlyForecast: [HourlyForecast] = []
    @Published var dailyForecast: [DailyForecast] = []
    @Published var timezone: String?
    
    private let weatherService = WeatherService.shared
    private var lastFetchTime: Date?
    private var lastLocation: CLLocation?
    private let minimumFetchInterval: TimeInterval = 900 // 15 minutes
    private let significantDistanceChange: CLLocationDistance = 1000 // 1 kilometer
    
    func fetchWeather(for location: CLLocation) async {
        // Check if we should fetch new data
        if let lastFetch = lastFetchTime,
           let lastLoc = lastLocation {
            let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
            let distanceFromLastFetch = location.distance(from: lastLoc)
            
            if timeSinceLastFetch < minimumFetchInterval && distanceFromLastFetch < significantDistanceChange {
                print("Skipping weather fetch - Last fetch was \(Int(timeSinceLastFetch))s ago and \(Int(distanceFromLastFetch))m away")
                return
            }
        }
        
        print("Attempting to fetch weather for location: \(location)")
        do {
            let weather = try await weatherService.weather(for: location)
            let geocoder = CLGeocoder()
            
            // Get timezone for the location
            if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
               let timezone = placemarks.first?.timeZone {
                DispatchQueue.main.async {
                    self.timezone = timezone.identifier
                }
            }
            
            print("Successfully received weather data")
            
            // Update fetch metadata
            lastFetchTime = Date()
            lastLocation = location
            
            DispatchQueue.main.async {
                print("Debug - Visibility: \(weather.currentWeather.visibility)")
                print("Debug - Sunrise: \(String(describing: weather.dailyForecast[0].sun.sunrise))")
                print("Debug - Sunset: \(String(describing: weather.dailyForecast[0].sun.sunset))")
                
                self.currentWeather = Weather(
                    temperature: weather.currentWeather.temperature.value,
                    feelsLike: weather.currentWeather.apparentTemperature.value,
                    highTemperature: weather.dailyForecast[0].highTemperature.value,
                    lowTemperature: weather.dailyForecast[0].lowTemperature.value,
                    condition: weather.currentWeather.condition,
                    humidity: weather.currentWeather.humidity * 100,
                    windSpeed: weather.currentWeather.wind.speed.value,
                    uvIndex: Int(weather.currentWeather.uvIndex.value),
                    airQualityIndex: 50,
                    sunrise: weather.dailyForecast[0].sun.sunrise ?? Date(),
                    sunset: weather.dailyForecast[0].sun.sunset ?? Date().addingTimeInterval(43200),
                    visibility: weather.currentWeather.visibility.value
                )
                
                // Set hourly forecast
                let now = Date()
                self.hourlyForecast = Array(weather.hourlyForecast.filter { $0.date >= now }.prefix(24)).map { hour in
                    HourlyForecast(
                        date: hour.date,
                        temperature: hour.temperature.value,
                        condition: hour.condition
                    )
                }
                
                // Set daily forecast
                self.dailyForecast = weather.dailyForecast.map { day in
                    DailyForecast(
                        date: day.date,
                        highTemperature: day.highTemperature.value,
                        lowTemperature: day.lowTemperature.value,
                        condition: day.condition,
                        sunrise: day.sun.sunrise,
                        sunset: day.sun.sunset
                    )
                }
            }
        } catch {
            print("Weather fetch error: \(error.localizedDescription)")
            print("Detailed error: \(error)")
        }
    }
}
