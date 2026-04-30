import Foundation

class SpeedCameraService {
    static let shared = SpeedCameraService()
    private let url = "https://driveassist-worker.plan7-studio.workers.dev/api/speed-camera"
    private let apiKey = "driveassist-mvp-2026"

    func fetchAll() async throws -> [SpeedCamera] {
        var request = URLRequest(url: URL(string: url)!)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(SpeedCameraResponse.self, from: data)
        return decoded.data
    }
}
