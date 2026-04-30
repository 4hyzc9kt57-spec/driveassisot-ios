import ActivityKit
import Foundation

struct DriveAssistAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var speedLimit: Int
        var currentSpeed: Int
        var nearestParking: String
        var parkingAvail: Int
        var isWarning: Bool
    }
    var routeName: String
}
