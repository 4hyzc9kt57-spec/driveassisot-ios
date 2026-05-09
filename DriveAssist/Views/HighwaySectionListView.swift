import SwiftUI
import CoreLocation

struct HighwaySectionListView: View {
    @State private var sections: [HighwaySection] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var directionFilter: DirectionFilter = .all
    @State private var isSortingByGPS = false

    enum DirectionFilter: String, CaseIterable {
        case all = "全部"
        case northEast = "北上／東行"
        case southWest = "南下／西行"
    }

    var filteredSections: [HighwaySection] {
        switch directionFilter {
        case .all:
            return sections
        case .northEast:
            return sections.filter { sec in
                let id = sec.id.uppercased()
                return id.contains("-N-") || id.contains("-E-")
            }
        case .southWest:
            return sections.filter { sec in
                let id = sec.id.uppercased()
                return id.contains("-S-") || id.contains("-W-")
            }
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView(isSortingByGPS ? "定位中 ..." : "載入中 ...")
                } else if let error = errorMessage {
                    Text("錯誤：\(error)").foregroundColor(.red)
                } else {
                    VStack(spacing: 0) {
                        Picker("方向", selection: $directionFilter) {
                            ForEach(DirectionFilter.allCases, id: \.self) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                        List(filteredSections) { sec in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(parseName(sec.id, fallback: sec.name))
                                        .font(.headline)
                                        .lineLimit(2)
                                    Label("\(sec.speed) km/h", systemImage: "car.fill")
                                        .font(.subheadline)
                                        .foregroundColor(speedColor(sec.level))
                                }
                                Spacer()
                                levelBadge(sec.level)
                            }
                            .padding(.vertical, 4)
                        }
                        .refreshable { await load() }
                    }
                }
            }
            .navigationTitle("高速公路路況")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await loadNearestFirst() }
                    } label: {
                        Image(systemName: "location.circle")
                    }
                }
            }
            .task { await load() }
        }
    }

    func loadNearestFirst() async {
        isSortingByGPS = true
        isLoading = true
        errorMessage = nil
        do {
            let all = try await HighwayService.shared.fetchSections()
            let location = await getCurrentLocation()
            if let loc = location {
                sections = all.sorted { a, b in
                    let da = distanceToSection(from: loc, section: a)
                    let db = distanceToSection(from: loc, section: b)
                    return da < db
                }
            } else {
                sections = all
                errorMessage = "無法取得定位，顯示預設排序"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        isSortingByGPS = false
    }

    func distanceToSection(from loc: CLLocation, section: HighwaySection) -> CLLocationDistance {
        guard let lat = section.lat, let lon = section.lon else {
            return CLLocationDistance.greatestFiniteMagnitude
        }
        let target = CLLocation(latitude: lat, longitude: lon)
        return loc.distance(from: target)
    }

    func getCurrentLocation() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            let mgr = CLLocationManager()
            class Delegate: NSObject, CLLocationManagerDelegate {
                var cont: CheckedContinuation<CLLocation?, Never>
                init(_ c: CheckedContinuation<CLLocation?, Never>) { cont = c }
                func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
                    cont.resume(returning: locs.last)
                    m.stopUpdatingLocation()
                }
                func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {
                    cont.resume(returning: nil)
                }
            }
            let d = Delegate(continuation)
            mgr.delegate = d
            mgr.desiredAccuracy = kCLLocationAccuracyHundredMeters
            mgr.requestLocation()
            objc_setAssociatedObject(mgr, "delegate", d, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    func parseName(_ id: String, fallback: String) -> String {
        if !fallback.hasPrefix("VD") && fallback.range(of: "[\\u4e00-\\u9fff]", options: .regularExpression) != nil {
            return fallback
        }
        let parts = id.components(separatedBy: "-")
        guard parts.count >= 3 else { return fallback }
        var highway = ""
        var direction = ""
        var km = ""
        var foundHighway = false
        for (i, part) in parts.enumerated() {
            if !foundHighway && part.count >= 2 && part.hasPrefix("N") {
                let numStr = String(part.dropFirst())
                if let num = Int(numStr) {
                    highway = "國道\(num)號"
                    foundHighway = true
                    if i + 1 < parts.count {
                        switch parts[i + 1] {
                        case "N": direction = "北上"
                        case "S": direction = "南下"
                        case "E": direction = "東行"
                        case "W": direction = "西行"
                        default: break
                        }
                    }
                    if i + 2 < parts.count, let d = Double(parts[i + 2]) {
                        km = String(format: "%.1f km", d)
                    }
                    break
                }
            }
        }
        if highway.isEmpty { return fallback }
        var result = highway
        if !direction.isEmpty { result += " \(direction)" }
        if !km.isEmpty { result += " \(km)" }
        return result
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            sections = try await HighwayService.shared.fetchSections()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func speedColor(_ level: Int) -> Color {
        switch level {
        case 0: return .green
        case 1: return .orange
        default: return .red
        }
    }

    @ViewBuilder
    func levelBadge(_ level: Int) -> some View {
        let label = level == 0 ? "順暢" : level == 1 ? "壅塞" : "停車"
        let color: Color = level == 0 ? .green : level == 1 ? .orange : .red
        Text(label)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}
