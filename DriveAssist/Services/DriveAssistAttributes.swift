import ActivityKit
import Foundation

struct ParkingSpot: Codable, Hashable {
    var name: String
    var dist: Int
    var avail: Int
    var lat: Double
    var lon: Double
}

struct DriveAssistAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var speedLimit: Int
        var currentSpeed: Int
        var isWarning: Bool
        var cameraLimit: Int
        var cameraDistance: Int
        var cameraRoad: String
        var nearestParking: String
        var parkingAvail: Int
        var parkingSpots: [ParkingSpot]
    }
    var routeName: String
}
