import Foundation

struct HighwaySection: Identifiable, Codable {
    let id: String
    let name: String
    let dir: String?
    let speed: Int
    let level: Int
    let updated: String?
}

struct HighwayData: Codable {
    let sections: [HighwaySection]
}

struct HighwayResponse: Codable {
    let data: HighwayData
}
