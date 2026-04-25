import Foundation

class ParkingService {
    static let shared = ParkingService()
    private let baseURL = "https://driveassist-worker.plan7-studio.workers.dev"
    private let apiKey = "driveassist-mvp-2026"

    func fetchNearby(lat: Double, lng: Double, radius: Int = 500) async throws -> [CarPark] {
        let url = URL(string: "\(baseURL)/api/parking?lat=\(lat)&lng=\(lng)&radius=\(radius)")!
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ParkingResponse.self, from: data)
        return response.data
    }
}
