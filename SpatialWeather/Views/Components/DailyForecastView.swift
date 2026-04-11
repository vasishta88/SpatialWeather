import SwiftUI

struct DailyForecastView: View {
    let forecast: [DailyForecast]
    let useCelsius: Bool
    let theme: WeatherTheme
    let surfaceStyle: WeatherSurfaceStyle

    var body: some View {
        WeatherCard(
            title: "10-Day Forecast",
            subtitle: "Daily outlook with high and low temperatures.",
            theme: theme,
            surfaceStyle: surfaceStyle
        ) {
            if forecast.isEmpty {
                Text("Daily forecast data will appear once weather loads.")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
            } else {
                VStack(spacing: 14) {
                    ForEach(Array(forecast.prefix(10).enumerated()), id: \.element.id) { index, day in
                        HStack(spacing: 14) {
                            Text(index == 0 ? "Today" : DateFormatters.formatAbbreviatedDay(day.date))
                                .font(.body.weight(.semibold))
                                .foregroundStyle(theme.primaryText)
                                .frame(width: 64, alignment: .leading)

                            Image(systemName: day.condition.systemIcon)
                                .font(.headline)
                                .foregroundStyle(theme.primaryText)
                                .frame(width: 24)

                            Spacer()

                            Text("\(formatTemperature(day.lowTemperature, useCelsius: useCelsius))°")
                                .font(.body.weight(.medium))
                                .foregroundStyle(theme.tertiaryText)

                            Capsule()
                                .fill(.white.opacity(0.14))
                                .frame(width: 54, height: 4)
                                .overlay(alignment: .leading) {
                                    Capsule()
                                        .fill(theme.accent)
                                        .frame(width: 30, height: 4)
                                }

                            Text("\(formatTemperature(day.highTemperature, useCelsius: useCelsius))°")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(theme.primaryText)
                        }

                        if day.id != forecast.prefix(10).last?.id {
                            Divider()
                                .overlay(theme.cardStroke)
                        }
                    }
                }
            }
        }
    }
}
