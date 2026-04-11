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
@MainActor
final class WeatherManager: ObservableObject {
    @Published var currentWeather: Weather?
    @Published var hourlyForecast: [HourlyForecast] = []
    @Published var dailyForecast: [DailyForecast] = []
    
    private let weatherService = WeatherService.shared
    private var lastFetchTime: Date?
    private var lastLocation: CLLocation?
    private var activeFetchID: UUID?
    private var activeFetchLocation: CLLocation?
    private let minimumFetchInterval: TimeInterval = 900 // 15 minutes
    private let significantDistanceChange: CLLocationDistance = 1000 // 1 kilometer
    private let activeFetchDistanceTolerance: CLLocationDistance = 100 // de-dupe only near-identical concurrent requests
    
    func forceRefetch(for location: CLLocation) async {
        lastFetchTime = nil
        await fetchWeather(for: location)
    }

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

        if let activeFetchLocation {
            let distanceFromActiveFetch = location.distance(from: activeFetchLocation)

            if distanceFromActiveFetch < activeFetchDistanceTolerance {
                print("Skipping weather fetch - A request is already in progress for a location \(Int(distanceFromActiveFetch))m away")
                return
            }
        }
        
        let fetchID = UUID()
        activeFetchID = fetchID
        activeFetchLocation = location
        defer {
            if activeFetchID == fetchID {
                activeFetchID = nil
                activeFetchLocation = nil
            }
        }

        print("Attempting to fetch weather for location: \(location)")
        do {
            let weather = try await weatherService.weather(for: location)
            guard activeFetchID == fetchID else {
                print("Discarding stale weather response")
                return
            }
            guard let todayForecast = weather.dailyForecast.first else {
                print("Weather fetch error: missing daily forecast data")
                return
            }
            
            print("Successfully received weather data")
            
            currentWeather = Weather(
                temperature: weather.currentWeather.temperature.value,
                feelsLike: weather.currentWeather.apparentTemperature.value,
                highTemperature: todayForecast.highTemperature.value,
                lowTemperature: todayForecast.lowTemperature.value,
                condition: weather.currentWeather.condition,
                humidity: weather.currentWeather.humidity * 100,
                windSpeed: weather.currentWeather.wind.speed.value,
                windDirection: weather.currentWeather.wind.compassDirection.abbreviation,
                uvIndex: Int(weather.currentWeather.uvIndex.value),
                airQualityIndex: -1,
                sunrise: todayForecast.sun.sunrise,
                sunset: todayForecast.sun.sunset,
                visibility: weather.currentWeather.visibility.value
            )
            
            let now = Date()
            hourlyForecast = Array(weather.hourlyForecast.filter { $0.date >= now }.prefix(24)).map { hour in
                HourlyForecast(
                    date: hour.date,
                    temperature: hour.temperature.value,
                    feelsLike: hour.apparentTemperature.value,
                    precipitationChance: hour.precipitationChance,
                    condition: hour.condition
                )
            }
            
            dailyForecast = weather.dailyForecast.map { day in
                DailyForecast(
                    date: day.date,
                    highTemperature: day.highTemperature.value,
                    lowTemperature: day.lowTemperature.value,
                    condition: day.condition,
                    sunrise: day.sun.sunrise,
                    sunset: day.sun.sunset
                )
            }

            // Update fetch metadata only after a successful, current response.
            lastFetchTime = Date()
            lastLocation = location
        } catch {
            print("Weather fetch error: \(error.localizedDescription)")
            print("Detailed error: \(error)")
        }
    }
}
