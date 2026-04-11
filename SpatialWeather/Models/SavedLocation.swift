import Foundation
import CoreLocation

struct SavedLocation: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
