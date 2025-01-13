//
//  DailyForecastView.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-13.
//

import SwiftUI
import Foundation

struct DailyForecastView: View {
    let forecast: [DailyForecast]
    let useCelsius: Bool
    let isNighttime: Bool
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(forecast) { day in
                    HStack {
                        Text(formatDay(day.date))
                            .font(.custom("MarkerFelt-Wide", size: 16))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 2)
                            .overlay {
                                Text(formatDay(day.date))
                                    .font(.custom("MarkerFelt-Wide", size: 16))
                                    .foregroundColor(.orange)
                                    .shadow(color: .black.opacity(0.8), radius: 1, x: 1, y: 1)
                                    .offset(x: -1, y: -1)
                            }
                            .frame(width: 100, alignment: .leading)
                        
                        WeatherSymbol(
                            icon: day.condition.systemIcon,
                            condition: day.condition,
                            width: 24,
                            height: 24,
                            isNighttime: isNighttime
                        )
                        
                        Spacer()
                        
                        HStack(spacing: 20) {
                            Text("L: \(formatTemperature(day.lowTemperature, useCelsius: useCelsius))°")
                                .font(.custom("MarkerFelt-Wide", size: 16))
                                .foregroundColor(.white.opacity(0.7))
                                .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 2)
                                .frame(width: 50, alignment: .trailing)
                            
                            Text("H: \(formatTemperature(day.highTemperature, useCelsius: useCelsius))°")
                                .font(.custom("MarkerFelt-Wide", size: 16))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 2)
                                .overlay {
                                    Text("H: \(formatTemperature(day.highTemperature, useCelsius: useCelsius))°")
                                        .font(.custom("MarkerFelt-Wide", size: 16))
                                        .foregroundColor(.orange)
                                        .shadow(color: .black.opacity(0.8), radius: 1, x: 1, y: 1)
                                        .offset(x: -1, y: -1)
                                }
                                .frame(width: 50, alignment: .trailing)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 8)
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
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"  // Full day name
        return formatter.string(from: date)
    }
}
