import Foundation
import CoreLocation
import Combine

@MainActor
class DriveViewModel: ObservableObject {
    @Published var currentSpeed: Int = 0
    @Published var nearestCamera: SpeedCamera?
    @Published var parkingSpots: [ParkingSpot] = []
    @Published var isActive: Bool = false

    private var locationManager = LocationManager()
    private var monitorTask: Task<Void, Never>?
    private var lastParkingLocation: CLLocation?
    private var alertedCameraIds: Set<String> = []

    private let cameraAlertRadius = 500  // 測速照相警戒範圍 m
    private let parkingUpdateDistance = 200.0  // 停車場更新距離 m
    private let parkingRadius = 1000  // 停車場搜尋半徑 m

    func start() {
        isActive = true
        locationManager.requestLocation()
        LiveActivityManager.shared.start()

        monitorTask = Task {
            var tick = 0
            while !Task.isCancelled && isActive {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 每 5 秒
                tick += 1
                guard let loc = locationManager.location else { continue }

                // 車速
                let speed = max(0, Int(loc.speed * 3.6)) // m/s → km/h
                currentSpeed = speed

                // 測速照相偵測
                await checkNearbyCamera(loc: loc)

                // 停車場更新（每 60 秒或移動 200m）
                let shouldUpdateParking = tick % 12 == 0 ||
                    lastParkingLocation.map { loc.distance(from: $0) > parkingUpdateDistance } ?? true
                if shouldUpdateParking {
                    await updateParking(loc: loc)
                    lastParkingLocation = loc
                }

                // 更新動態島
                await updateLiveActivity(loc: loc)
            }
        }
    }

    func stop() async {
        isActive = false
        monitorTask?.cancel()
        monitorTask = nil
        alertedCameraIds.removeAll()
        await LiveActivityManager.shared.stop()
    }

    private func checkNearbyCamera(loc: CLLocation) async {
        do {
            let cameras = try await SpeedCameraService.shared.fetchNearby(
                lat: loc.coordinate.latitude,
                lng: loc.coordinate.longitude,
                radius: cameraAlertRadius
            )
            nearestCamera = cameras.first

            // 觸發警戒（只在第一次進入範圍時）
            if let cam = cameras.first, !alertedCameraIds.contains(cam.id) {
                alertedCameraIds.insert(cam.id)
                await LiveActivityManager.shared.update(
                    speedLimit: cam.limit,
                    currentSpeed: currentSpeed,
                    cameraLimit: cam.limit,
                    cameraDistance: cam.dist ?? 0,
                    cameraRoad: cam.road,
                    nearestParking: parkingSpots.first?.name ?? "",
                    parkingAvail: parkingSpots.first?.avail ?? 0,
                    parkingSpots: parkingSpots,
                    triggerAlert: true
                )
                return
            }

            // 離開範圍後清除已警戒記錄
            let activeIds = Set(cameras.map { $0.id })
            alertedCameraIds = alertedCameraIds.intersection(activeIds)

        } catch {
            print("Camera check error: \(error)")
        }
    }

    private func updateParking(loc: CLLocation) async {
        do {
            let carParks = try await ParkingService.shared.fetchNearby(
                lat: loc.coordinate.latitude,
                lng: loc.coordinate.longitude,
                radius: parkingRadius
            )
            parkingSpots = carParks.prefix(3).map {
                ParkingSpot(
                    name: $0.name,
                    dist: $0.dist ?? 0,
                    avail: $0.avail ?? 0,
                    lat: $0.lat,
                    lon: $0.lon
                )
            }
        } catch {
            print("Parking update error: \(error)")
        }
    }

    private func updateLiveActivity(loc: CLLocation) async {
        let cam = nearestCamera
        await LiveActivityManager.shared.update(
            speedLimit: cam?.limit ?? 0,
            currentSpeed: currentSpeed,
            cameraLimit: cam?.limit ?? 0,
            cameraDistance: cam?.dist ?? 0,
            cameraRoad: cam?.road ?? "",
            nearestParking: parkingSpots.first?.name ?? "",
            parkingAvail: parkingSpots.first?.avail ?? 0,
            parkingSpots: parkingSpots,
            triggerAlert: false
        )
    }
}
