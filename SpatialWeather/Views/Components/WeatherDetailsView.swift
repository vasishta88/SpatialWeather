import SwiftUI

struct WeatherDetailsView: View {
    enum Tab {
        case now, hourly, daily
    }
    
    let weather: Weather?
    let hourlyForecast: [HourlyForecast]
    let dailyForecast: [DailyForecast]
    let useCelsius: Bool
    let isNighttime: Bool
    @State private var selectedTab: Tab = .hourly
    @Binding var selectedHour: Date?
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            TabView(selection: $selectedTab) {
                CurrentWeatherView(
                    weather: weather,
                    useCelsius: useCelsius
                )
                    .tag(Tab.now)
                HourlyForecastView(
                    forecast: hourlyForecast,
                    useCelsius: useCelsius,
                    isNighttime: isNighttime,
                    selectedHour: $selectedHour
                )
                    .tag(Tab.hourly)
                DailyForecastView(
                    forecast: dailyForecast,
                    useCelsius: useCelsius,
                    isNighttime: isNighttime
                )
                    .tag(Tab.daily)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 150)
            .background(Color.clear)
            
            // Tab bar
            HStack(spacing: 30) {
                TabButton(title: "Now", isSelected: selectedTab == .now, isNighttime: isNighttime) {
                    withAnimation { 
                        selectedTab = .now 
                        selectedHour = nil 
                    }
                }
                TabButton(title: "Hourly", isSelected: selectedTab == .hourly, isNighttime: isNighttime) {
                    withAnimation { selectedTab = .hourly }
                }
                TabButton(title: "Daily", isSelected: selectedTab == .daily, isNighttime: isNighttime) {
                    withAnimation { selectedTab = .daily }
                }
            }
            .padding(.vertical, 12)
            .background(Color.clear)
        }
        .background(Color.clear)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let isNighttime: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("MarkerFelt-Wide", size: 20))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 2)
                .overlay {
                    if isSelected {
                        Text(title)
                            .font(.custom("MarkerFelt-Wide", size: 20))
                            .foregroundColor(.orange)
                            .shadow(color: .black.opacity(0.8), radius: 1, x: 1, y: 1)
                            .offset(x: -1, y: -1)
                    }
                }
        }
    }
}
