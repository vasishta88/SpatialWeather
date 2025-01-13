//
//  WeatherDetailCard.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-14.
//


import SwiftUI

struct WeatherDetailCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.6), radius: 2, x: 1, y: 1)
            
            Text(value)
                .font(.custom("MarkerFelt-Wide", size: 20))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 2)
                .overlay {
                    Text(value)
                        .font(.custom("MarkerFelt-Wide", size: 20))
                        .foregroundColor(.orange)
                        .shadow(color: .black.opacity(0.8), radius: 1, x: 1, y: 1)
                        .offset(x: -1, y: -1)
                }
                .multilineTextAlignment(.center)
            
            Text(title)
                .font(.custom("MarkerFelt-Wide", size: 14))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 1)
                .multilineTextAlignment(.center)
        }
        .frame(height: 90)
        .padding(.vertical, 8)
    }
}

#Preview {
    Group {
        // Single card preview
        WeatherDetailCard(
            title: "Humidity",
            value: "65%",
            icon: "humidity.fill"
        )
        .previewLayout(.sizeThatFits)
        .padding()
        
        // Grid preview
        WeatherDetailsGrid(
            weather: Weather(
                temperature: 25.0,
                feelsLike: 27.0,
                highTemperature: 28.0,
                lowTemperature: 20.0,
                condition: .clear,
                humidity: 65.0,
                windSpeed: 12.0,
                uvIndex: 5,
                airQualityIndex: 45,
                sunrise: Optional(Date()),
                sunset: Optional(Date().addingTimeInterval(43200)),
                visibility: 10.0
            ),
            useCelsius: true
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}