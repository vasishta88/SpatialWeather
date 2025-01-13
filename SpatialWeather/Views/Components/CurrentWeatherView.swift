import SwiftUI

struct CurrentWeatherView: View {
    let weather: Weather?
    let useCelsius: Bool
    
    var body: some View {
        WeatherDetailsGrid(weather: weather, useCelsius: useCelsius)
            .frame(height: 150)
            .background(Color.clear)
    }
} 