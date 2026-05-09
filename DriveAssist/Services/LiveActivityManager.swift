import ActivityKit
import Foundation

@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    private var activity: Activity<DriveAssistAttributes>?

    @Published var isRunning = false

    func start(routeName: String = "行車助手") {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activity 未授權")
            return
        }
        guard activity == nil else { return }

        let attributes = DriveAssistAttributes(routeName: routeName)
        let state = DriveAssistAttributes.ContentState(
            speedLimit: 0,
            currentSpeed: 0,
            isWarning: false,
            cameraLimit: 0,
            cameraDistance: 0,
            cameraRoad: "",
            nearestParking: "",
            parkingAvail: 0,
            parkingSpots: []
        )
        let content = ActivityContent(state: state, staleDate: nil)

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            isRunning = true
            print("Live Activity 啟動：\(activity?.id ?? "")")
        } catch {
            print("Live Activity 啟動失敗：\(error)")
        }
    }

    func update(speedLimit: Int, currentSpeed: Int,
                cameraLimit: Int = 0, cameraDistance: Int = 0,
                cameraRoad: String = "",
                nearestParking: String = "", parkingAvail: Int = 0,
                parkingSpots: [ParkingSpot] = [],
                triggerAlert: Bool = false) async {
        guard let activity else { return }

        let isWarning = speedLimit > 0 && currentSpeed > speedLimit
        let state = DriveAssistAttributes.ContentState(
            speedLimit: speedLimit,
            currentSpeed: currentSpeed,
            isWarning: isWarning,
            cameraLimit: cameraLimit,
            cameraDistance: cameraDistance,
            cameraRoad: cameraRoad,
            nearestParking: nearestParking,
            parkingAvail: parkingAvail,
            parkingSpots: parkingSpots
        )

        let content = ActivityContent(state: state, staleDate: nil)

        if triggerAlert && cameraLimit > 0 {
            let road = cameraRoad.isEmpty ? "" : "\n\(cameraRoad)"
            let alertConfig = AlertConfiguration(
                title: "⚠️ 前方測速照相",
                body: "速限 \(cameraLimit) km/h　距離 \(cameraDistance) m\(road)",
                sound: .default
            )
            await activity.update(content, alertConfiguration: alertConfig)
            print("Live Activity 警戒觸發：\(cameraLimit) km/h \(cameraDistance) m")
        } else {
            await activity.update(content)
        }
    }

    func stop() async {
        let state = DriveAssistAttributes.ContentState(
            speedLimit: 0,
            currentSpeed: 0,
            isWarning: false,
            cameraLimit: 0,
            cameraDistance: 0,
            cameraRoad: "",
            nearestParking: "",
            parkingAvail: 0,
            parkingSpots: []
        )
        let content = ActivityContent(state: state, staleDate: nil)
        await activity?.end(content, dismissalPolicy: .immediate)
        activity = nil
        isRunning = false
    }
}
