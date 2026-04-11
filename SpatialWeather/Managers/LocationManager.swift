//
//  LocationManager.swift//
//  Created by Vasishta Atmuri on 2024-11-13.
//

import CoreLocation

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let weatherManager: WeatherManager
    @Published var location: CLLocation?
    @Published var locationName: String = "Loading..."
    @Published var authorizationStatus: CLAuthorizationStatus?
    private var lastGeocodeTime: Date?
    private var lastGeocodedLocation: CLLocation?
    @Published var useCurrentLocation: Bool = true
    @Published var savedLocations: [SavedLocation] = []
    @Published var timeZone: TimeZone = .autoupdatingCurrent {
        didSet {
            DateFormatters.timeZone = timeZone
        }
    }

    init(weatherManager: WeatherManager) {
        self.weatherManager = weatherManager
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus

        loadSavedLocations()

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    func requestLocation() {
        useCurrentLocation = true

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationName = "Locating..."
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    func setCustomLocation(name: String, location: CLLocation) {
        useCurrentLocation = false
        manager.stopUpdatingLocation()
        self.locationName = name
        self.location = location
        
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let tz = placemarks?.first?.timeZone {
                    self?.timeZone = tz
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard useCurrentLocation, let location = locations.last else { return }
        self.location = location
        
        let shouldReverseGeocode: Bool

        if let lastGeocodeTime, let lastGeocodedLocation {
            let timeSinceLastGeocode = Date().timeIntervalSince(lastGeocodeTime)
            let distanceSinceLastGeocode = location.distance(from: lastGeocodedLocation)
            shouldReverseGeocode = timeSinceLastGeocode > 30 || distanceSinceLastGeocode > 250
        } else {
            shouldReverseGeocode = true
        }

        if shouldReverseGeocode {
            geocoder.cancelGeocode()
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                DispatchQueue.main.async {
                    self?.locationName = placemarks?.first?.locality ?? "Unknown Location"
                    if let tz = placemarks?.first?.timeZone {
                        self?.timeZone = tz
                    }
                    self?.lastGeocodeTime = Date()
                    self?.lastGeocodedLocation = location
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            requestLocation()
        default:
            break
        }
    }

    func fetchWeather(for location: CLLocation) async {
        await weatherManager.fetchWeather(for: location)
    }
    
    func addSavedLocation(name: String, coordinate: CLLocationCoordinate2D) {
        let newLocation = SavedLocation(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude)
        if !savedLocations.contains(where: { $0.name == name }) {
            savedLocations.insert(newLocation, at: 0)
            saveLocations()
        }
    }
    
    func removeSavedLocation(id: UUID) {
        savedLocations.removeAll { $0.id == id }
        saveLocations()
    }
    
    private func saveLocations() {
        if let encoded = try? JSONEncoder().encode(savedLocations) {
            UserDefaults.standard.set(encoded, forKey: "savedLocations")
        }
    }
    
    private func loadSavedLocations() {
        if let data = UserDefaults.standard.data(forKey: "savedLocations"),
           let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) {
            self.savedLocations = decoded
        }
    }
}
