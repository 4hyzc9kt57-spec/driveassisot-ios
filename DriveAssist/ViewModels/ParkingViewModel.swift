import Foundation
import CoreLocation

@MainActor
class ParkingViewModel: ObservableObject {
    @Published var carParks: [CarPark] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var locationManager = LocationManager()

    init() {
        locationManager.requestLocation()
    }

    func loadFromGPS() async {
        if let loc = locationManager.location {
            await load(lat: loc.coordinate.latitude, lng: loc.coordinate.longitude)
        } else {
            // GPS 尚未取得，用台北信義區當備用
            await load(lat: 25.0478, lng: 121.5318)
        }
    }

    func load(lat: Double, lng: Double) async {
        isLoading = true
        errorMessage = nil
        do {
            carParks = try await ParkingService.shared.fetchNearby(lat: lat, lng: lng)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
