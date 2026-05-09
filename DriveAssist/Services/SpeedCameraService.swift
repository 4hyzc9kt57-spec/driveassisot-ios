import Foundation

class SpeedCameraService {
    static let shared = SpeedCameraService()
    private let baseURL = "https://driveassist-worker.plan7-studio.workers.dev"
    private let apiKey = "driveassist-mvp-2026"

    func fetchNearby(lat: Double, lng: Double, radius: Int = 5000) async throws -> [SpeedCamera] {
        let url = URL(string: "\(baseURL)/api/speed-camera?lat=\(lat)&lng=\(lng)&r=\(radius)")!
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(SpeedCameraResponse.self, from: data)
        return decoded.data
    }
}
