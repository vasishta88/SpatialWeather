import SwiftUI

struct SettingsView: View {
    @Binding var useCelsius: Bool
    var locationManager: LocationManager
    @State private var showLocationPicker = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Units of Measurement")) {
                    Picker("Temperature Unit", selection: $useCelsius) {
                        Text("Celsius").tag(true)
                        Text("Fahrenheit").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Location")) {
                    Button("Select Location") {
                        showLocationPicker.toggle()
                    }
                    .sheet(isPresented: $showLocationPicker) {
                        LocationPickerView(locationManager: locationManager) {
                            showLocationPicker = false
                        }
                    }
                }

                Section(header: Text("Data & Privacy")) {
                    Link("Data & Privacy Policy", destination: URL(string: "https://your-privacy-policy-url.com")!)
                }

                Section(header: Text("About")) {
                    Link("About the App", destination: URL(string: "https://your-about-url.com")!)
                }

                Section {
                    Button("Reset Settings") {
                        resetSettings()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func resetSettings() {
        // Reset units to Celsius
        useCelsius = true
        
        // Reset location to current location
        locationManager.requestLocation() // This will trigger the location manager to fetch the current location
    }
}