//
//  HourlyForecastView.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-13.
//

import SwiftUI
import Foundation


struct HourlyForecastView: View {
    let forecast: [HourlyForecast]
    let useCelsius: Bool
    let isNighttime: Bool
    @Binding var selectedHour: Date?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            let groupedForecasts = groupForecastByDay()
            LazyHStack(spacing: 0) {
                ForEach(groupedForecasts, id: \.date) { dayForecast in
                    VStack(alignment: .leading, spacing: 6) {
                        // Day header
                        DayHeaderView(date: dayForecast.date)
                        
                        // Hourly items
                        LazyHStack(spacing: 8) {
                            ForEach(dayForecast.forecasts) { hour in
                                HourlyItemView(
                                    hour: hour,
                                    useCelsius: useCelsius,
                                    isSelected: selectedHour == hour.date,
                                    isNighttime: isNighttime
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedHour = hour.date
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .padding(.vertical, 4)
                    
                    if dayForecast.date != groupedForecasts.last?.date {
                        Divider()
                            .background(Color.white.opacity(0.3))
                            .padding(.vertical, 2)
                    }
                }
            }
        }
        .onChange(of: selectedHour) { oldValue, newValue in
            print("selectedHour changed from \(String(describing: oldValue)) to \(String(describing: newValue))")
        }
        .frame(height: 150)
        .background(
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
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
    
    private func groupForecastByDay() -> [DayForecast] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: forecast) { forecast in
            calendar.startOfDay(for: forecast.date)
        }
        return grouped.map { date, forecasts in
            DayForecast(date: date, forecasts: forecasts.sorted { $0.date < $1.date })
        }.sorted { $0.date < $1.date }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: date)
    }
}

private struct HourlyItemView: View {
    let hour: HourlyForecast
    let useCelsius: Bool
    let isSelected: Bool
    let isNighttime: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(formatHour(hour.date))
                .font(.custom("MarkerFelt-Wide", size: 16))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 2)
                .overlay {
                    Text(formatHour(hour.date))
                        .font(.custom("MarkerFelt-Wide", size: 16))
                        .foregroundColor(.orange)
                        .shadow(color: .black.opacity(0.8), radius: 1, x: 1, y: 1)
                        .offset(x: -1, y: -1)
                }
            
            WeatherSymbol(
                icon: hour.condition.systemIcon,
                condition: hour.condition,
                width: 30,
                height: 30,
                isNighttime: isNighttime
            )
            
            Text("\(formatTemperature(hour.temperature, useCelsius: useCelsius))°")
                .font(.custom("MarkerFelt-Wide", size: 20))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 2)
                .overlay {
                    Text("\(formatTemperature(hour.temperature, useCelsius: useCelsius))°")
                        .font(.custom("MarkerFelt-Wide", size: 20))
                        .foregroundColor(.orange)
                        .shadow(color: .black.opacity(0.8), radius: 1, x: 1, y: 1)
                        .offset(x: -1, y: -1)
                }
        }
        .frame(width: 60)
        .padding(12)
        .background(isSelected ? .white.opacity(0.2) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date)
            .replacingOccurrences(of: "AM", with: "am")
            .replacingOccurrences(of: "PM", with: "pm")
    }
}

private struct DayForecast {
    let date: Date
    let forecasts: [HourlyForecast]
}

private struct DayHeaderView: View {
    let date: Date
    
    var body: some View {
        Text(formatDate(date))
            .font(.custom("MarkerFelt-Wide", size: 16))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 2)
            .overlay {
                Text(formatDate(date))
                    .font(.custom("MarkerFelt-Wide", size: 16))
                    .foregroundColor(.orange)
                    .shadow(color: .black.opacity(0.8), radius: 1, x: 1, y: 1)
                    .offset(x: -1, y: -1)
            }
            .frame(width: 80, alignment: .leading)
            .padding(.horizontal, 12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: date)
    }
}
