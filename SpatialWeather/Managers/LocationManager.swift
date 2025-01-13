//
//  LocationManager.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-13.
//


import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    @Published var location: CLLocation?
    @Published var locationName: String = "Loading..."
    @Published var authorizationStatus: CLAuthorizationStatus?
    private var lastGeocodeTime: Date?
    @Published var useCurrentLocation: Bool = true
    
    private var weatherManager: WeatherManager

    init(weatherManager: WeatherManager) {
        self.weatherManager = weatherManager
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        // Only start updating if we want to use current location
        if useCurrentLocation {
            manager.startUpdatingLocation()
        }
    }
    
    func requestLocation() {
        useCurrentLocation = true
        manager.startUpdatingLocation()
    }
    
    func setCustomLocation(name: String, location: CLLocation) {
        useCurrentLocation = false
        manager.stopUpdatingLocation()
        self.locationName = name
        self.location = location
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard useCurrentLocation, let location = locations.first else { return }
        self.location = location
        
        // Only geocode if more than 10 seconds have passed
        if lastGeocodeTime == nil || Date().timeIntervalSince(lastGeocodeTime!) > 10 {
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                DispatchQueue.main.async {
                    self?.locationName = placemarks?.first?.locality ?? "Unknown Location"
                    self?.lastGeocodeTime = Date()
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
            manager.requestLocation()
        default:
            break
        }
    }
    
    // Fetch weather for a specific location
    func fetchWeather(for location: CLLocation) async {
        await weatherManager.fetchWeather(for: location)
    }
}
