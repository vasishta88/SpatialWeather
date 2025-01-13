import SwiftUI
import CoreLocation
import MapKit

struct LocationPickerView: View {
    @ObservedObject var locationManager: LocationManager
    var onLocationSelected: () -> Void
    @State private var searchText = ""
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var searchedLocations: [(name: String, coordinate: CLLocationCoordinate2D)] = []
    private let searchCompleter = MKLocalSearchCompleter()
    
    let locations: [(name: String, coordinate: CLLocationCoordinate2D)] = [
        ("New York", CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)),
        ("Los Angeles", CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)),
        ("Chicago", CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298)),
        ("Houston", CLLocationCoordinate2D(latitude: 29.7604, longitude: -95.3698)),
        ("Phoenix", CLLocationCoordinate2D(latitude: 33.4484, longitude: -112.0740)),
        ("Philadelphia", CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652)),
        ("San Antonio", CLLocationCoordinate2D(latitude: 29.4241, longitude: -98.4936)),
        ("San Diego", CLLocationCoordinate2D(latitude: 32.7157, longitude: -117.1611)),
        ("Dallas", CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970)),
        ("San Jose", CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863))
    ]
    
    var body: some View {
        NavigationView {
            List {
                // Current Location Section
                Section(header: Text("Current Location")) {
                    Button(action: {
                        locationManager.requestLocation()
                        onLocationSelected()
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Use Current Location")
                        }
                        .foregroundColor(.white)
                    }
                }
                
                // Search Section
                Section(header: Text("Search")) {
                    TextField("Search for a place...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.white)
                        .accentColor(.white)
                        .submitLabel(.search)
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchResults.isEmpty {
                        ForEach(searchResults, id: \.self) { result in
                            Button(action: {
                                addSearchResultToLocations(result)
                            }) {
                                VStack(alignment: .leading) {
                                    Text(result.title)
                                        .foregroundColor(.white)
                                    Text(result.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                
                // Searched Locations Section
                if !searchedLocations.isEmpty {
                    Section(header: Text("Search Results")) {
                        ForEach(searchedLocations, id: \.name) { location in
                            Button(action: {
                                selectLocation(location)
                            }) {
                                Text(location.name)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                
                // Popular Cities Section
                Section(header: Text("Popular Cities")) {
                    ForEach(locations, id: \.name) { location in
                        Button(action: {
                            selectLocation(location)
                        }) {
                            Text(location.name)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Select Location")
            .navigationBarItems(trailing: Button("Done") {
                onLocationSelected()
            })
        }
        .onAppear {
            setupSearchCompleter()
        }
        .onChange(of: searchText) { _, newValue in
            if !newValue.isEmpty {
                searchCompleter.queryFragment = newValue
            }
        }
    }
    
    private func setupSearchCompleter() {
        searchCompleter.delegate = SearchCompleterDelegate(searchResults: $searchResults)
    }
    
    private func addSearchResultToLocations(_ result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
            
            DispatchQueue.main.async {
                let locationName = "\(result.title), \(result.subtitle)"
                let newLocation = (name: locationName, coordinate: coordinate)
                if !searchedLocations.contains(where: { $0.name == locationName }) {
                    searchedLocations.insert(newLocation, at: 0)
                }
                searchText = ""
                searchResults = []
            }
        }
    }
    
    private func selectLocation(_ location: (name: String, coordinate: CLLocationCoordinate2D)) {
        // Extract just the city name from the full location string
        let cityName = location.name.components(separatedBy: ",")[0].trimmingCharacters(in: .whitespaces)
        
        locationManager.setCustomLocation(
            name: cityName,
            location: CLLocation(latitude: location.coordinate.latitude, 
                               longitude: location.coordinate.longitude)
        )
        
        Task {
            await locationManager.fetchWeather(for: locationManager.location!)
        }
        
        onLocationSelected()
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else {
                print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                if let firstResult = response.mapItems.first {
                    let location = firstResult.placemark
                    let locationName = [
                        location.name,
                        location.locality,
                        location.administrativeArea,
                        location.country
                    ].compactMap { $0 }.joined(separator: ", ")
                    
                    let newLocation = (
                        name: locationName,
                        coordinate: location.coordinate
                    )
                    
                    if !searchedLocations.contains(where: { $0.name == locationName }) {
                        searchedLocations.insert(newLocation, at: 0)
                    }
                    searchText = ""
                    searchResults = []
                }
            }
        }
    }
}

// Search Completer Delegate
class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate, ObservableObject {
    @Binding var searchResults: [MKLocalSearchCompletion]
    
    init(searchResults: Binding<[MKLocalSearchCompletion]>) {
        _searchResults = searchResults
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search failed with error: \(error.localizedDescription)")
    }
} 
