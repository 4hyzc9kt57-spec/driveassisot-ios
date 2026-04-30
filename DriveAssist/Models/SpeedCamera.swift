import Foundation

struct SpeedCamera: Identifiable, Codable {
    let id: String
    let road: String
    let limit: Int
    let lat: Double
    let lon: Double
    let az: Int?
    let lane: Int?
}

struct SpeedCameraResponse: Codable {
    let data: [SpeedCamera]
}
