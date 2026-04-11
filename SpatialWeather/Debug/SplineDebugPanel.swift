#if DEBUG
import SwiftUI

final class SplineDebugState: ObservableObject {
    @Published var isEnabled = false
    @Published var family: SimplifiedWeatherFamily = .clear
    @Published var season: Season = .summer
    @Published var isNighttime = false

    var effectiveFamily: SimplifiedWeatherFamily {
        family
    }

    var effectiveIsNighttime: Bool {
        isNighttime
    }

    var splineState: SplineWeatherState {
        SplineWeatherState(
            family: family,
            season: season,
            isNighttime: isNighttime
        )
    }
}

struct SplineDebugPanel: View {
    @ObservedObject var state: SplineDebugState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Override") {
                    Toggle("Enable Debug Override", isOn: $state.isEnabled)
                }

                Section("State") {
                    Picker("Season", selection: $state.season) {
                        ForEach(Season.allCases) { season in
                            Text(season.title).tag(season)
                        }
                    }

                    Picker("Weather", selection: $state.family) {
                        ForEach(SimplifiedWeatherFamily.allCases) { family in
                            Text(family.title).tag(family)
                        }
                    }

                    Toggle("Night Mode", isOn: $state.isNighttime)
                }

                Section("Spline Variables") {
                    LabeledContent("weatherIndex", value: String(Int(state.splineState.weatherIndex)))
                    LabeledContent("timeofDay", value: String(Int(state.splineState.timeOfDay)))
                    LabeledContent("season", value: String(Int(state.splineState.season)))
                }
            }
            .navigationTitle("Spline Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
#endif
