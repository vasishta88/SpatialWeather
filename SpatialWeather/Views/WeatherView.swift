//
//  WeatherView.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-13.
//


import SwiftUI
import CoreLocation

struct WeatherView: View {
    @StateObject private var weatherManager = WeatherManager()
    @StateObject private var locationManager = LocationManager(weatherManager: WeatherManager())
    @AppStorage("useCelsius") private var useCelsius = true
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            WeatherMainContent(
                weatherManager: weatherManager,
                locationManager: locationManager,
                useCelsius: useCelsius
            )
            .task {
                if let location = locationManager.location {
                    await weatherManager.fetchWeather(for: location)
                }
            }
            .onChange(of: locationManager.location) { oldValue, newValue in
                if let location = newValue {
                    Task {
                        await weatherManager.fetchWeather(for: location)
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(useCelsius: $useCelsius, locationManager: locationManager)
        }
    }
}

#Preview {
    WeatherView()
}
