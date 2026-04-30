import Foundation

class HighwayService {
    static let shared = HighwayService()
    private let url = "https://driveassist-worker.plan7-studio.workers.dev/api/highway"
    private let apiKey = "driveassist-mvp-2026"

    func fetchSections() async throws -> [HighwaySection] {
        var request = URLRequest(url: URL(string: url)!)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(HighwayResponse.self, from: data)
        return decoded.data.sections
    }
}
