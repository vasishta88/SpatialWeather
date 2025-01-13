//
//  WeatherDetailsGrid.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-13.
//
import SwiftUI

struct WeatherDetailsGrid: View {
    let weather: Weather?
    let useCelsius: Bool
    
    var body: some View {
        ZStack {
            // Frosted glass base
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .opacity(0.7)
            
            // Soft white overlay for frost effect
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .opacity(0.15)
            
            // Comic book style border
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.white.opacity(0.6), lineWidth: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                        .padding(2)
                )
            
            // Top highlight for glass effect
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.4),
                            .white.opacity(0.1),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Content
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 16) {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        Group {
                            WeatherDetailCard(
                                title: "Feels Like",
                                value: "\(formatTemperature(weather?.feelsLike ?? 0, useCelsius: useCelsius))°",
                                icon: "thermometer"
                            )
                            
                            WeatherDetailCard(
                                title: "Humidity",
                                value: formatHumidity(weather?.humidity),
                                icon: "humidity.fill"
                            )
                            
                            WeatherDetailCard(
                                title: "Wind",
                                value: formatWindSpeed(weather?.windSpeed),
                                icon: "wind"
                            )
                        }
                        
                        Group {
                            WeatherDetailCard(
                                title: "UV Index",
                                value: formatUVIndex(weather?.uvIndex),
                                icon: "sun.max.fill"
                            )
                            
                            WeatherDetailCard(
                                title: "Air Quality",
                                value: formatAQI(weather?.airQualityIndex),
                                icon: "aqi.medium"
                            )
                            
                            WeatherDetailCard(
                                title: "Visibility",
                                value: formatVisibility(weather?.visibility),
                                icon: "eye.fill"
                            )
                        }
                        
                        if let sunrise = weather?.sunrise, let sunset = weather?.sunset {
                            Group {
                                WeatherDetailCard(
                                    title: "Sunrise",
                                    value: formatTime(sunrise),
                                    icon: "sunrise.fill"
                                )
                                
                                WeatherDetailCard(
                                    title: "Sunset",
                                    value: formatTime(sunset),
                                    icon: "sunset.fill"
                                )
                                
                                WeatherDetailCard(
                                    title: "Daylight",
                                    value: formatDaylight(sunrise, sunset),
                                    icon: "sun.and.horizon.fill"
                                )
                            }
                        }
                    }
                }
                .padding(12)
            }
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
    
    // Formatter functions
    private func formatHumidity(_ humidity: Double?) -> String {
        guard let humidity = humidity else { return "N/A" }
        return "\(Int(humidity))%"
    }
    
    private func formatWindSpeed(_ speed: Double?) -> String {
        guard let speed = speed else { return "N/A" }
        return "\(Int(speed)) km/h"
    }
    
    private func formatUVIndex(_ uv: Int?) -> String {
        guard let uv = uv else { return "N/A" }
        let description: String
        switch uv {
        case 0...2: description = "Low"
        case 3...5: description = "Moderate"
        case 6...7: description = "High"
        case 8...10: description = "Very High"
        default: description = "Extreme"
        }
        return "\(uv) (\(description))"
    }
    
    private func formatAQI(_ aqi: Int?) -> String {
        guard let aqi = aqi else { return "N/A" }
        let description: String
        switch aqi {
        case 0...50: description = "Good"
        case 51...100: description = "Moderate"
        case 101...150: description = "Unhealthy for Sensitive Groups"
        case 151...200: description = "Unhealthy"
        case 201...300: description = "Very Unhealthy"
        default: description = "Hazardous"
        }
        return "\(aqi) (\(description))"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatVisibility(_ visibility: Double?) -> String {
        guard let visibility = visibility else { return "N/A" }
        if visibility < 1 {
            return "\(Int(visibility * 1000))m"
        }
        return "\(Int(visibility))km"
    }
    
    private func formatDaylight(_ sunrise: Date, _ sunset: Date) -> String {
        let duration = sunset.timeIntervalSince(sunrise)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}
