import SwiftUI
import CoreLocation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var useCelsius: Bool
    @ObservedObject var locationManager: LocationManager

    #if DEBUG
    private var debugState: SplineDebugState?
    @State private var showDebugPanel = false
    #endif

    init(useCelsius: Binding<Bool>, locationManager: LocationManager) {
        self._useCelsius = useCelsius
        self.locationManager = locationManager
        #if DEBUG
        self.debugState = nil
        #endif
    }

    #if DEBUG
    init(useCelsius: Binding<Bool>, locationManager: LocationManager, debugState: SplineDebugState) {
        self._useCelsius = useCelsius
        self.locationManager = locationManager
        self.debugState = debugState
    }
    #endif

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    SettingsSectionCard(title: "Units of Measurement") {
                        Text("Choose how temperature values are displayed across the app.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Picker("Temperature Unit", selection: $useCelsius) {
                            Text("Celsius").tag(true)
                            Text("Fahrenheit").tag(false)
                        }
                        .pickerStyle(.segmented)
                    }

                    SettingsSectionCard(title: "Location") {
                        NavigationLink {
                            SettingsLocationPickerScreen(locationManager: locationManager)
                        } label: {
                            SettingsNavigationRow(
                                title: "Select Location",
                                subtitle: locationManager.locationName,
                                systemImage: "location.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if !locationManager.savedLocations.isEmpty {
                        SettingsSectionCard(title: "Saved Locations") {
                            ForEach(locationManager.savedLocations) { location in
                                HStack {
                                    Button {
                                        let cityName = location.name.components(separatedBy: ",")[0].trimmingCharacters(in: .whitespaces)
                                        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                                        locationManager.setCustomLocation(name: cityName, location: clLocation)
                                        Task {
                                            await locationManager.fetchWeather(for: clLocation)
                                        }
                                        dismiss()
                                    } label: {
                                        SettingsNavigationRow(
                                            title: location.name,
                                            subtitle: "Quick Select",
                                            systemImage: "mappin.circle.fill"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(role: .destructive) {
                                        locationManager.removeSavedLocation(id: location.id)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .padding(.leading, 8)
                                    .buttonStyle(.plain)
                                }
                                
                                if location.id != locationManager.savedLocations.last?.id {
                                    Divider()
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                    }

                    SettingsSectionCard(title: "Data & Privacy") {
                        Text("Location is used only while the app is open to fetch weather for your selected place.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    SettingsSectionCard(title: "About") {
                        SettingsInfoRow(
                            title: "Version",
                            value: appVersion,
                            systemImage: "info.circle"
                        )
                    }

                    SettingsSectionCard(title: "Reset") {
                        Button("Reset Settings") {
                            resetSettings()
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    #if DEBUG
                    if debugState != nil {
                        SettingsSectionCard(title: "Developer") {
                            Button {
                                showDebugPanel = true
                            } label: {
                                SettingsNavigationRow(
                                    title: "Scene Debug Panel",
                                    subtitle: "Inspect live spline variables.",
                                    systemImage: "ladybug"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    #endif
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(settingsBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        #if DEBUG
        .sheet(isPresented: $showDebugPanel) {
            if let debugState {
                SplineDebugPanel(state: debugState)
            }
        }
        #endif
    }

    private var settingsBackground: some View {
        LinearGradient(
            colors: [
                Color(.systemGray6),
                Color(.systemBackground),
                Color(.systemGray5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func resetSettings() {
        useCelsius = true
        locationManager.requestLocation()
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}

private struct SettingsSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color(uiColor: .separator).opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

private struct SettingsNavigationRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

private struct SettingsInfoRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 26)

            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

private struct SettingsLocationPickerScreen: View {
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        LocationPickerView(
            locationManager: locationManager,
            onLocationSelected: { dismiss() },
            showsNavigationWrapper: false
        )
        .navigationTitle("Select Location")
        .navigationBarTitleDisplayMode(.inline)
    }
}
