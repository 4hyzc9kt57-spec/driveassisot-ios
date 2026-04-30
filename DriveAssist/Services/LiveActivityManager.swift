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
            nearestParking: "",
            parkingAvail: 0,
            isWarning: false
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
                nearestParking: String = "", parkingAvail: Int = 0) async {
        let isWarning = speedLimit > 0 && currentSpeed > speedLimit
        let state = DriveAssistAttributes.ContentState(
            speedLimit: speedLimit,
            currentSpeed: currentSpeed,
            nearestParking: nearestParking,
            parkingAvail: parkingAvail,
            isWarning: isWarning
        )
        let content = ActivityContent(state: state, staleDate: nil)
        await activity?.update(content)
    }

    func stop() async {
        let state = DriveAssistAttributes.ContentState(
            speedLimit: 0,
            currentSpeed: 0,
            nearestParking: "",
            parkingAvail: 0,
            isWarning: false
        )
        let content = ActivityContent(state: state, staleDate: nil)
        await activity?.end(content, dismissalPolicy: .immediate)
        activity = nil
        isRunning = false
    }
}
