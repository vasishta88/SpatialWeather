import SwiftUI

struct WeatherDetailsGrid: View {
    let weather: Weather?
    let useCelsius: Bool
    let theme: WeatherTheme
    let surfaceStyle: WeatherSurfaceStyle

    private var items: [DetailItem] {
        guard let weather else { return [] }

        var details: [DetailItem] = [
            DetailItem(title: "Feels Like", value: "\(formatTemperature(weather.feelsLike, useCelsius: useCelsius))°", icon: "thermometer.medium"),
            DetailItem(title: "Humidity", value: "\(Int(weather.humidity))%", icon: "humidity.fill"),
            DetailItem(title: "Wind", value: "\(Int(weather.windSpeed)) km/h \(weather.windDirection)", icon: "wind"),
            DetailItem(title: "UV Index", value: formatUVIndex(weather.uvIndex), icon: "sun.max.fill"),
            DetailItem(title: "Visibility", value: formatVisibility(weather.visibility), icon: "eye.fill")
        ]

        if weather.airQualityIndex >= 0 {
            details.append(
                DetailItem(title: "Air Quality", value: formatAQI(weather.airQualityIndex), icon: "aqi.medium")
            )
        }

        if let sunrise = weather.sunrise {
            details.append(
                DetailItem(title: "Sunrise", value: DateFormatters.formatShortTime(sunrise), icon: "sunrise.fill")
            )
        }

        if let sunset = weather.sunset {
            details.append(
                DetailItem(title: "Sunset", value: DateFormatters.formatShortTime(sunset), icon: "sunset.fill")
            )
        }

        if let sunrise = weather.sunrise, let sunset = weather.sunset {
            details.append(
                DetailItem(title: "Daylight", value: formatDaylight(sunrise, sunset), icon: "sun.and.horizon.fill")
            )
        }

        return details
    }

    var body: some View {
        WeatherCard(
            title: "Weather Details",
            subtitle: "Secondary conditions for the current location.",
            theme: theme,
            surfaceStyle: surfaceStyle
        ) {
            if items.isEmpty {
                Text("Detailed metrics will appear once current conditions load.")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(items) { item in
                        WeatherDetailCard(item: item, theme: theme)
                    }
                }
            }
        }
    }

    private func formatUVIndex(_ uvIndex: Int) -> String {
        switch uvIndex {
        case 0...2:
            return "\(uvIndex) Low"
        case 3...5:
            return "\(uvIndex) Moderate"
        case 6...7:
            return "\(uvIndex) High"
        case 8...10:
            return "\(uvIndex) Very High"
        default:
            return "\(uvIndex) Extreme"
        }
    }

    private func formatAQI(_ aqi: Int) -> String {
        switch aqi {
        case 0...50:
            return "\(aqi) Good"
        case 51...100:
            return "\(aqi) Moderate"
        case 101...150:
            return "\(aqi) Unhealthy"
        case 151...200:
            return "\(aqi) Very Unhealthy"
        default:
            return "\(aqi) Hazardous"
        }
    }

    private func formatVisibility(_ visibility: Double) -> String {
        if visibility < 1 {
            return "\(Int(visibility * 1000)) m"
        }
        return "\(Int(visibility)) km"
    }

    private func formatDaylight(_ sunrise: Date, _ sunset: Date) -> String {
        let duration = sunset.timeIntervalSince(sunrise)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}

struct DetailItem: Identifiable {
    var id: String { title }
    let title: String
    let value: String
    let icon: String
}
