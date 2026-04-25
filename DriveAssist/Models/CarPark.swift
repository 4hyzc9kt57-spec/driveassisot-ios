import Foundation

struct CarPark: Identifiable, Decodable {
    let id: String
    let name: String
    let lat: Double
    let lon: Double
    let total: Int?
    let avail: Int?
    let fare: String?
    let dist: Int?
}

struct ParkingResponse: Decodable {
    let data: [CarPark]
}
