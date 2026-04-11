import SwiftUI

struct HourlyForecastView: View {
    let forecast: [HourlyForecast]
    let dailyForecast: [DailyForecast]
    let useCelsius: Bool
    let theme: WeatherTheme
    let surfaceStyle: WeatherSurfaceStyle
    let onHourSelection: (Date?) -> Void
    let onScrollStateChange: (Bool) -> Void
    @Binding var selectedHour: Date?

    private let calendar = Calendar.current

    init(
        forecast: [HourlyForecast],
        dailyForecast: [DailyForecast],
        useCelsius: Bool,
        theme: WeatherTheme,
        surfaceStyle: WeatherSurfaceStyle = .liveGlass,
        selectedHour: Binding<Date?>,
        onHourSelection: @escaping (Date?) -> Void = { _ in },
        onScrollStateChange: @escaping (Bool) -> Void = { _ in }
    ) {
        self.forecast = forecast
        self.dailyForecast = dailyForecast
        self.useCelsius = useCelsius
        self.theme = theme
        self.surfaceStyle = surfaceStyle
        self._selectedHour = selectedHour
        self.onHourSelection = onHourSelection
        self.onScrollStateChange = onScrollStateChange
    }

    var body: some View {
        WeatherCard(
            title: "Hourly Forecast",
            subtitle: selectedHour == nil ? "Tap an hour to preview the scene and temperature." : "Tap Now to return to live conditions.",
            theme: theme,
            surfaceStyle: surfaceStyle
        ) {
            if forecast.isEmpty {
                Text("Hourly data will appear once the latest forecast loads.")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        Button {
                            selectHour(nil)
                        } label: {
                            HourlyChipView(
                                title: "Now",
                                systemIcon: "clock.fill",
                                temperature: nil,
                                precipitationChance: nil,
                                isSelected: selectedHour == nil,
                                theme: theme
                            )
                        }
                        .buttonStyle(.plain)

                        ForEach(forecast.prefix(24)) { hour in
                            Button {
                                selectHour(hour.date)
                            } label: {
                                HourlyChipView(
                                    title: formatHourLabel(hour.date),
                                    systemIcon: hour.condition.systemIcon(isNighttime: isNighttime(for: hour.date)),
                                    temperature: "\(formatTemperature(hour.temperature, useCelsius: useCelsius))°",
                                    precipitationChance: hour.precipitationChance,
                                    isSelected: isSelected(hour.date),
                                    theme: theme
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onScrollPhaseChange { _, newPhase in
                    onScrollStateChange(newPhase.isScrolling)
                }
            }
        }
    }

    private func selectHour(_ hour: Date?) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedHour = hour
            onHourSelection(hour)
        }
    }

    private func formatHourLabel(_ date: Date) -> String {
        DateFormatters.formatHour(date)
            .replacingOccurrences(of: "AM", with: "am")
            .replacingOccurrences(of: "PM", with: "pm")
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selectedHour else { return false }
        return calendar.isDate(date, equalTo: selectedHour, toGranularity: .hour)
    }

    private func isNighttime(for date: Date) -> Bool {
        if let matchingDay = dailyForecast.first(where: { calendar.isDate($0.date, inSameDayAs: date) }),
           let sunrise = matchingDay.sunrise,
           let sunset = matchingDay.sunset {
            return date < sunrise || date > sunset
        }

        // Fallback when sunrise/sunset data is unavailable.
        // Use hour < 6 || >= 19 to avoid misclassifying early-sunset winter evenings.
        let hour = calendar.component(.hour, from: date)
        return hour < 6 || hour >= 19
    }
}

private struct HourlyChipView: View {
    let title: String
    let systemIcon: String
    let temperature: String?
    let precipitationChance: Double?
    let isSelected: Bool
    let theme: WeatherTheme

    private var showPrecip: Bool {
        (precipitationChance ?? 0) >= 0.1
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? theme.primaryText : theme.secondaryText)

            Image(systemName: systemIcon)
                .font(.subheadline)
                .foregroundStyle(theme.primaryText)

            Text(showPrecip ? "\(Int((precipitationChance ?? 0) * 100))%" : " ")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(showPrecip ? Color.cyan.opacity(0.9) : .clear)

            Text(temperature ?? " ")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.primaryText)
                .frame(minHeight: 16)
        }
        .frame(width: 64, height: 96)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isSelected ? theme.selectedFill : .white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? theme.accent.opacity(0.45) : theme.cardStroke, lineWidth: 1)
        )
    }
}
