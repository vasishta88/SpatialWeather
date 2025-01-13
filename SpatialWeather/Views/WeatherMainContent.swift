//
//  WeatherMainContent.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-13.
//

import SwiftUI
import WeatherKit


struct WeatherMainContent: View {
    @ObservedObject var weatherManager: WeatherManager
    @ObservedObject var locationManager: LocationManager
    let useCelsius: Bool
    @State private var selectedHour: Date?
    @State private var showLocationPicker = false
    @State private var showSettings = false
    
    private var isNighttime: Bool {
        guard let currentWeather = weatherManager.currentWeather else {
            return false
        }
        
        // Get the timezone for the current location
        let locationTimeZone = TimeZone(identifier: weatherManager.timezone ?? TimeZone.current.identifier) ?? TimeZone.current
        let calendar = Calendar.current
        
        // If we have a selected hour, use that
        if let selectedHour = selectedHour,
           let selectedDay = weatherManager.dailyForecast.first(where: { calendar.isDate($0.date, inSameDayAs: selectedHour) }),
           let sunrise = selectedDay.sunrise,
           let sunset = selectedDay.sunset {
            return selectedHour < sunrise || selectedHour > sunset
        }
        
        // For current time, use the current weather's sunrise/sunset
        if let sunrise = currentWeather.sunrise,
           let sunset = currentWeather.sunset {
            let now = Date()
            return now < sunrise || now > sunset
        }
        
        return false
    }
    
    private var selectedWeather: HourlyForecast? {
        guard let selectedHour = selectedHour else { return nil }
        return weatherManager.hourlyForecast.first { $0.date == selectedHour }
    }
    
    private var backgroundColor: Color {
        let condition = selectedWeather?.condition ?? weatherManager.currentWeather?.condition ?? .clear
        
        if isNighttime {
            // Night colors
            switch condition {
            case .cloudy, .mostlyCloudy, .partlyCloudy:
                return Color(hex: "2A3B50")  // Cloudy night
            case .drizzle, .rain, .heavyRain, .sunShowers, .freezingDrizzle,
                 .freezingRain, .hurricane, .tropicalStorm, .hail:
                return Color(hex: "1F2E40")  // Rain night
            case .clear, .mostlyClear, .hot:
                return Color(hex: "001D3D")  // Clear night
            case .snow, .heavySnow, .blizzard, .blowingSnow, .frigid,
                 .flurries, .sunFlurries, .sleet, .wintryMix:
                return Color(hex: "1A2B4B")  // Snowy night
            case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms,
                 .strongStorms:
                return Color(hex: "1D2835")  // Thunderstorm night
            default:
                return Color(hex: "2A3B50")  // Default to cloudy night
            }
        } else {
            // Day colors
            switch condition {
            case .snow, .heavySnow, .blizzard, .blowingSnow, .frigid,
                 .flurries, .sunFlurries, .sleet, .wintryMix:
                return Color(hex: "E5F4FB")  // Snowy day
            case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms,
                 .strongStorms:
                return Color(hex: "647A8D")  // Thunderstorm day
            case .drizzle, .rain, .heavyRain, .sunShowers, .freezingDrizzle,
                 .freezingRain, .hurricane, .tropicalStorm, .hail:
                return Color(hex: "88AFC1")  // Rainy day
            case .cloudy, .mostlyCloudy, .partlyCloudy:
                return Color(hex: "B0D4E3")  // Cloudy day
            case .clear, .mostlyClear, .hot:
                return Color(hex: "91FFF8")  // Clear day
            default:
                return Color(hex: "B0D4E3")  // Default to cloudy day
            }
        }
    }
    
    private var displayTemperature: Double {
        let temp = if let selectedHour = selectedHour,
           let hourlyWeather = weatherManager.hourlyForecast.first(where: { $0.date == selectedHour }) {
            hourlyWeather.temperature
        } else {
            weatherManager.currentWeather?.temperature ?? 0
        }
        
        return useCelsius ? temp : (temp * 9/5 + 32)
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            // 3D Weather Symbol - Moved to background
            Group {
                if let weather = selectedWeather {
                    WeatherSymbol3D(
                        condition: weather.condition,
                        isNighttime: isNighttime
                    )
                } else if let currentWeather = weatherManager.currentWeather {
                    WeatherSymbol3D(
                        condition: currentWeather.condition,
                        isNighttime: isNighttime
                    )
                } else {
                    ProgressView()
                }
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.2), value: selectedHour)
            
            // Content overlay
            VStack(spacing: 0) {
                // Top bar with location and menu
                HStack {
                    Spacer()
                    
                    // Location button
                    Button(action: {
                        showLocationPicker.toggle()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 3)
                                .overlay {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.orange)
                                        .shadow(color: .black.opacity(0.8), radius: 1, x: 2, y: 2)
                                        .offset(x: -2, y: -2)
                                }
                            
                            Text(locationManager.locationName)
                                .font(.custom("MarkerFelt-Wide", size: 36))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 3)
                                .overlay {
                                    Text(locationManager.locationName)
                                        .font(.custom("MarkerFelt-Wide", size: 36))
                                        .foregroundColor(.orange)
                                        .shadow(color: .black.opacity(0.8), radius: 1, x: 2, y: 2)
                                        .offset(x: -2, y: -2)
                                }
                        }
                    }
                    
                    Spacer()
                    
                    // Settings button
                    Button(action: {
                        showSettings.toggle()
                    }) {
                        ZStack {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 3)
                                .overlay {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.orange)
                                        .shadow(color: .black.opacity(0.8), radius: 1, x: 2, y: 2)
                                        .offset(x: -2, y: -2)
                                }
                        }
                        .rotationEffect(.degrees(isNighttime ? 0 : 30))
                        .animation(.easeInOut(duration: 0.2), value: isNighttime)
                    }
                    .frame(width: 44, height: 44)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Temperature and condition
                HStack(spacing: 16) {
                    Text("\(Int(displayTemperature))°")
                        .font(.custom("MarkerFelt-Wide", size: 96))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 4)
                        .overlay {
                            Text("\(Int(displayTemperature))°")
                                .font(.custom("MarkerFelt-Wide", size: 96))
                                .foregroundColor(.orange)
                                .shadow(color: .black.opacity(0.8), radius: 1, x: 3, y: 3)
                                .offset(x: -3, y: -3)
                        }
                        .animation(.easeInOut(duration: 0.2), value: displayTemperature)
                    
                    HStack(spacing: 8) {
                        Image(systemName: selectedWeather?.condition.systemIcon ?? weatherManager.currentWeather?.condition.systemIcon ?? "clear.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.6), radius: 2, x: 1, y: 1)
                        Text(selectedWeather?.condition.description ?? weatherManager.currentWeather?.condition.description ?? "Clear")
                            .font(.custom("MarkerFelt-Wide", size: 28))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 2)
                            .overlay {
                                Text(selectedWeather?.condition.description ?? weatherManager.currentWeather?.condition.description ?? "Clear")
                                    .font(.custom("MarkerFelt-Wide", size: 28))
                                    .foregroundColor(.orange)
                                    .shadow(color: .black.opacity(0.8), radius: 1, x: 1, y: 1)
                                    .offset(x: -1, y: -1)
                            }
                    }
                }
                
                Spacer()
                
                // Bottom Details
                WeatherDetailsView(
                    weather: weatherManager.currentWeather,
                    hourlyForecast: weatherManager.hourlyForecast,
                    dailyForecast: weatherManager.dailyForecast,
                    useCelsius: useCelsius,
                    isNighttime: isNighttime,
                    selectedHour: $selectedHour
                )
                .background(Color.clear)
            }
            .background(Color.clear)
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(locationManager: locationManager) {
                showLocationPicker = false
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(useCelsius: .constant(useCelsius), locationManager: locationManager)
        }
    }
}

// Extract location and temperature view to separate component
private struct LocationAndTemperatureView: View {
    let locationName: String
    let displayTemperature: Double
    let condition: WeatherKit.WeatherCondition
    let conditionDescription: String
    @Binding var showLocationPicker: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                showLocationPicker.toggle()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 3)
                        .overlay {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.orange)
                                .shadow(color: .black.opacity(0.8), radius: 1, x: 2, y: 2)
                                .offset(x: -2, y: -2)
                        }
                    
                    Text(locationName)
                        .font(.custom("MarkerFelt-Wide", size: 36))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 3)
                        .overlay {
                            Text(locationName)
                                .font(.custom("MarkerFelt-Wide", size: 36))
                                .foregroundColor(.orange)
                                .shadow(color: .black.opacity(0.8), radius: 1, x: 2, y: 2)
                                .offset(x: -2, y: -2)
                        }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .opacity(0.3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
                                .padding(1)
                        )
                )
            }
            
            HStack(spacing: 16) {
                Text("\(Int(displayTemperature))°")
                    .font(.custom("MarkerFelt-Wide", size: 96))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 4)
                    .overlay {
                        Text("\(Int(displayTemperature))°")
                            .font(.custom("MarkerFelt-Wide", size: 96))
                            .foregroundColor(.orange)
                            .shadow(color: .black.opacity(0.8), radius: 1, x: 3, y: 3)
                            .offset(x: -3, y: -3)
                    }
                    .animation(.easeInOut(duration: 0.2), value: displayTemperature)
                
                HStack(spacing: 8) {
                    Image(systemName: condition.systemIcon)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 2, x: 1, y: 1)
                    Text(conditionDescription)
                        .font(.custom("MarkerFelt-Wide", size: 28))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 2)
                        .overlay {
                            Text(conditionDescription)
                                .font(.custom("MarkerFelt-Wide", size: 28))
                                .foregroundColor(.orange)
                                .shadow(color: .black.opacity(0.8), radius: 1, x: 1, y: 1)
                                .offset(x: -1, y: -1)
                        }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
