import Foundation
import CoreLocation
import Combine

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
        isLoading = true
        errorMessage = nil

        // 等待位置，最多10秒
        var waited = 0
        while locationManager.location == nil && waited < 20 {
            try? await Task.sleep(nanoseconds: 500_000_000)
            waited += 1
        }

        if let loc = locationManager.location {
            await load(lat: loc.coordinate.latitude, lng: loc.coordinate.longitude)
        } else {
            // 逾時用台北信義區備用
            await load(lat: 25.0478, lng: 121.5318)
        }
    }

    func refresh() async {
        await loadFromGPS()
    }

    func load(lat: Double, lng: Double) async {
        do {
            carParks = try await ParkingService.shared.fetchNearby(lat: lat, lng: lng)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
