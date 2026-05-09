import Foundation
import CoreLocation

@MainActor
class SpeedCameraViewModel: ObservableObject {
    @Published var cameras: [SpeedCamera] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var locationManager = LocationManager()

    private var currentTask: Task<Void, Never>?

    init() {
        locationManager.requestLocation()
    }

    func loadFromGPS() async {
        currentTask?.cancel()
        currentTask = Task {
            defer { isLoading = false }
            isLoading = true
            errorMessage = nil

            var waited = 0
            while locationManager.location == nil && waited < 20 {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(nanoseconds: 500_000_000)
                waited += 1
            }

            guard !Task.isCancelled else { return }

            if let loc = locationManager.location {
                await load(lat: loc.coordinate.latitude, lng: loc.coordinate.longitude)
            } else {
                errorMessage = "無法取得位置，請確認定位權限"
            }
        }
        await currentTask?.value
    }

    func refresh() async {
        await loadFromGPS()
    }

    func load(lat: Double, lng: Double) async {
        guard !Task.isCancelled else { return }
        do {
            cameras = try await SpeedCameraService.shared.fetchNearby(lat: lat, lng: lng)
            if cameras.isEmpty {
                errorMessage = "附近 5km 內無測速照相"
            }
        } catch {
            if (error as? URLError)?.code == .cancelled { return }
            errorMessage = error.localizedDescription
        }
    }
}
