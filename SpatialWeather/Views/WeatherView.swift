//
//  WeatherView.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-13.
//


import SwiftUI

struct WeatherView: View {
    @StateObject private var weatherManager: WeatherManager
    @StateObject private var locationManager: LocationManager
    @AppStorage("useCelsius") private var useCelsius = true

    init() {
        let weatherManager = WeatherManager()
        _weatherManager = StateObject(wrappedValue: weatherManager)
        _locationManager = StateObject(wrappedValue: LocationManager(weatherManager: weatherManager))
    }
    
    var body: some View {
        WeatherMainContent(
            weatherManager: weatherManager,
            locationManager: locationManager,
            useCelsius: $useCelsius
        )
        .task {
            if let location = locationManager.location {
                await weatherManager.fetchWeather(for: location)
            }
        }
        .onChange(of: locationManager.location) { _, newValue in
            if let location = newValue {
                Task {
                    await weatherManager.fetchWeather(for: location)
                }
            }
        }
    }
}

#Preview {
    WeatherView()
}
