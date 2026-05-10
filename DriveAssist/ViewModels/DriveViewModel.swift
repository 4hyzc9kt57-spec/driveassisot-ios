import Foundation
import CoreLocation
import Combine

@MainActor
class DriveViewModel: ObservableObject {
    @Published var currentSpeed: Int = 0
    @Published var nearestCamera: SpeedCamera?
    @Published var parkingSpots: [ParkingSpot] = []
    @Published var isActive: Bool = false

    var autoStartEnabled: Bool {
        UserDefaults.standard.bool(forKey: "autoStartEnabled")
    }

    private var locationManager = LocationManager()
    private var monitorTask: Task<Void, Never>?
    private var lastParkingLocation: CLLocation?
    private var alertedCameraIds: Set<String> = []

    private var isAlertActive: Bool = false
    private var alertLockTask: Task<Void, Never>?

    private var stillTicks: Int = 0
    private var isPollingSuspended: Bool = false

    private let parkingUpdateDistance = 200.0
    private let parkingRadius = 1000

    // 方位角容差 30 度
    private let azTolerance = 30

    private func alertRadius(for speed: Int) -> Int {
        speed < 60 ? 200 : 500
    }

    // 方位角比對：接受正向（az）或反向（az±180）各 30 度容差
    private func isHeadingMatch(az: Int, heading: Double) -> Bool {
        let h = Int(heading)

        // 正向比對
        let diffForward = abs(az - h)
        let normalizedForward = min(diffForward, 360 - diffForward)

        // 反向比對（az+180，取模 360）
        let azReverse = (az + 180) % 360
        let diffReverse = abs(azReverse - h)
        let normalizedReverse = min(diffReverse, 360 - diffReverse)

        return normalizedForward <= azTolerance || normalizedReverse <= azTolerance
    }

    func start() {
        guard !isActive else { return }
        isActive = true
        stillTicks = 0
        isPollingSuspended = false
        locationManager.requestLocation()
        LiveActivityManager.shared.start()

        monitorTask = Task {
            var tick = 0
            while !Task.isCancelled && isActive {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                tick += 1
                guard let loc = locationManager.location else { continue }

                let speed = max(0, Int(loc.speed * 3.6))
                currentSpeed = speed

                if speed > 10 && isPollingSuspended {
                    isPollingSuspended = false
                    stillTicks = 0
                    print("恢復 API polling")
                }

                if speed == 0 {
                    stillTicks += 1
                    if stillTicks >= 36 && !isPollingSuspended {
                        isPollingSuspended = true
                        print("靜止 3 分鐘，暫停 API polling")
                    }
                } else {
                    stillTicks = 0
                }

                if isPollingSuspended {
                    await updateLiveActivity(cam: nearestCamera)
                    continue
                }

                await checkNearbyCamera(loc: loc, speed: speed)

                let shouldUpdateParking = tick % 12 == 0 ||
                    lastParkingLocation.map { loc.distance(from: $0) > parkingUpdateDistance } ?? true
                if shouldUpdateParking {
                    await updateParking(loc: loc)
                    lastParkingLocation = loc
                }

                if !isAlertActive {
                    await updateLiveActivity(cam: nearestCamera)
                }
            }
        }
    }

    func startAutoMonitor() {
        guard !isActive else { return }
        locationManager.requestLocation()

        Task {
            while !isActive {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard let loc = locationManager.location else { continue }
                let speed = max(0, Int(loc.speed * 3.6))
                if speed > 10 {
                    print("自動啟動行車模式（車速 \(speed) km/h）")
                    start()
                }
            }
        }
    }

    func stop() async {
        isActive = false
        monitorTask?.cancel()
        monitorTask = nil
        alertLockTask?.cancel()
        alertLockTask = nil
        alertedCameraIds.removeAll()
        isAlertActive = false
        stillTicks = 0
        isPollingSuspended = false
        await LiveActivityManager.shared.stop()
    }

    private func checkNearbyCamera(loc: CLLocation, speed: Int) async {
        let radius = alertRadius(for: speed)
        do {
            let cameras = try await SpeedCameraService.shared.fetchNearby(
                lat: loc.coordinate.latitude,
                lng: loc.coordinate.longitude,
                radius: radius
            )

            let heading = loc.course

            let filtered = cameras.filter { cam in
                guard let az = cam.az else { return true }

                // 車速過低或 heading 無效時不觸發
                guard heading >= 0 && speed >= 5 else { return false }

                // 支援雙向：正向或反向都接受
                return isHeadingMatch(az: az, heading: heading)
            }

            nearestCamera = filtered.first

            if let cam = filtered.first, !alertedCameraIds.contains(cam.id) {
                alertedCameraIds.insert(cam.id)

                isAlertActive = true
                alertLockTask?.cancel()
                alertLockTask = Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    isAlertActive = false
                }

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

            let activeIds = Set(filtered.map { $0.id })
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

    private func updateLiveActivity(cam: SpeedCamera?) async {
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
