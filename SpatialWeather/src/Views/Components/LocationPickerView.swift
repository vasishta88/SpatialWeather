import SwiftUI
import CoreLocation
import MapKit

struct LocationPickerView: View {
    @ObservedObject var locationManager: LocationManager
    var onLocationSelected: () -> Void
    let showsNavigationWrapper: Bool
    @State private var searchText = ""
    @StateObject private var searchManager = SearchCompleterManager()
    
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
    
    init(
        locationManager: LocationManager,
        onLocationSelected: @escaping () -> Void,
        showsNavigationWrapper: Bool = true
    ) {
        self.locationManager = locationManager
        self.onLocationSelected = onLocationSelected
        self.showsNavigationWrapper = showsNavigationWrapper
    }

    var body: some View {
        Group {
            if showsNavigationWrapper {
                NavigationStack {
                    pickerContent
                        .navigationTitle("Select Location")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    onLocationSelected()
                                }
                            }
                        }
                }
            } else {
                pickerContent
            }
        }
        .onChange(of: searchText) { _, newValue in
            searchManager.setQuery(newValue)
        }
    }

    private var pickerContent: some View {
        List {
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

            Section(header: Text("Search")) {
                TextField("Search for a place...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .foregroundColor(.white)
                    .accentColor(.white)
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch()
                    }

                if !searchManager.searchResults.isEmpty {
                    ForEach(searchManager.searchResults, id: \.self) { result in
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

            if !locationManager.savedLocations.isEmpty {
                Section(header: Text("Saved Locations")) {
                    ForEach(locationManager.savedLocations) { location in
                        Button(action: {
                            selectLocation((name: location.name, coordinate: location.coordinate))
                        }) {
                            Text(location.name)
                                .foregroundColor(.white)
                        }
                    }
                }
            }

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
    }
    

    
    private func addSearchResultToLocations(_ result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
            
            DispatchQueue.main.async {
                let locationName = "\(result.title), \(result.subtitle)"
                locationManager.addSavedLocation(name: locationName, coordinate: coordinate)
                searchText = ""
                searchManager.clearResults()
            }
        }
    }
    
    private func selectLocation(_ location: (name: String, coordinate: CLLocationCoordinate2D)) {
        // Extract just the city name from the full location string
        let cityName = location.name.components(separatedBy: ",")[0].trimmingCharacters(in: .whitespaces)
        let selectedLocation = CLLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        locationManager.setCustomLocation(
            name: cityName,
            location: selectedLocation
        )

        Task {
            await locationManager.fetchWeather(for: selectedLocation)
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
                    
                    locationManager.addSavedLocation(name: locationName, coordinate: location.coordinate)
                    searchText = ""
                    searchManager.clearResults()
                }
            }
        }
    }
}

final class SearchCompleterManager: NSObject, MKLocalSearchCompleterDelegate, ObservableObject {
    @Published var searchResults: [MKLocalSearchCompletion] = []
    
    private lazy var completer: MKLocalSearchCompleter = {
        let c = MKLocalSearchCompleter()
        c.delegate = self
        return c
    }()

    override init() {
        super.init()
    }

    func setQuery(_ query: String) {
        if query.isEmpty {
            clearResults()
        } else {
            completer.queryFragment = query
        }
    }

    func clearResults() {
        searchResults = []
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.searchResults = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("Search failed with error: \(error.localizedDescription)")
        }
    }
}
