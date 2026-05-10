import SwiftUI
import CoreLocation

struct HighwaySectionListView: View {
    @State private var sections: [HighwaySection] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var directionFilter: DirectionFilter = .all
    @State private var isSortingByGPS = false
    @State private var nearestInfo: String? = nil
    @State private var userLocation: CLLocation? = nil

    enum DirectionFilter: String, CaseIterable {
        case all = "全部"
        case northEast = "北上／東行"
        case southWest = "南下／西行"
    }

    var filteredAndSorted: [HighwaySection] {
        let merged = mergeSections(sections)
        switch directionFilter {
        case .all:
            // 依距離排序
            if let loc = userLocation {
                return merged.sorted { a, b in
                    distanceToSection(from: loc, section: a) < distanceToSection(from: loc, section: b)
                }
            }
            return merged
        case .northEast:
            // 北上：從使用者位置公里數往遞減排（數字越小越北）
            let filtered = merged.filter {
                let id = $0.id.uppercased()
                return id.contains("-N-") || id.contains("-E-")
            }
            if let loc = userLocation {
                // 找使用者在北上路段的最近公里數
                let nearest = filtered
                    .filter { $0.lat != nil && $0.lon != nil }
                    .min { distanceToSection(from: loc, section: $0) < distanceToSection(from: loc, section: $1) }
                let userKm = nearest.map { kmFromId($0.id) } ?? Double.infinity
                // 從使用者位置往北（公里數遞減）
                return filtered
                    .filter { kmFromId($0.id) <= userKm }
                    .sorted { kmFromId($0.id) > kmFromId($1.id) }
            }
            return filtered.sorted { kmFromId($0.id) > kmFromId($1.id) }
        case .southWest:
            // 南下：從使用者位置公里數往遞增排（數字越大越南）
            let filtered = merged.filter {
                let id = $0.id.uppercased()
                return id.contains("-S-") || id.contains("-W-")
            }
            if let loc = userLocation {
                let nearest = filtered
                    .filter { $0.lat != nil && $0.lon != nil }
                    .min { distanceToSection(from: loc, section: $0) < distanceToSection(from: loc, section: $1) }
                let userKm = nearest.map { kmFromId($0.id) } ?? 0.0
                return filtered
                    .filter { kmFromId($0.id) >= userKm }
                    .sorted { kmFromId($0.id) < kmFromId($1.id) }
            }
            return filtered.sorted { kmFromId($0.id) < kmFromId($1.id) }
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
                        if let info = nearestInfo {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text(info)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.08))
                        }

                        Picker("方向", selection: $directionFilter) {
                            ForEach(DirectionFilter.allCases, id: \.self) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                        List(filteredAndSorted) { sec in
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
                        Image(systemName: userLocation != nil ? "location.circle.fill" : "location.circle")
                            .foregroundColor(userLocation != nil ? .blue : .primary)
                    }
                }
            }
            .task { await load() }
        }
    }

    func mergeSections(_ input: [HighwaySection]) -> [HighwaySection] {
        var groups: [String: [HighwaySection]] = [:]
        for sec in input {
            let parts = sec.id.components(separatedBy: "-")
            var key = sec.id
            if parts.count >= 4 {
                key = "\(parts[0])-\(parts[1])-\(parts[2])-\(parts[3])"
            }
            groups[key, default: []].append(sec)
        }
        return groups.map { _, group in
            let avgSpeed = group.map { $0.speed }.reduce(0, +) / group.count
            let base = group[0]
            return HighwaySection(
                id: base.id,
                name: base.name,
                dir: base.dir,
                speed: avgSpeed,
                level: congestionLevel(avgSpeed),
                updated: base.updated,
                lat: base.lat,
                lon: base.lon
            )
        }
    }

    func congestionLevel(_ speed: Int) -> Int {
        if speed >= 60 { return 0 }
        if speed >= 30 { return 1 }
        return 2
    }

    func loadNearestFirst() async {
        isSortingByGPS = true
        isLoading = true
        errorMessage = nil
        nearestInfo = nil
        do {
            let all = try await HighwayService.shared.fetchSections()
            let location = await getCurrentLocation()
            if let loc = location {
                userLocation = loc
                let nearest = all
                    .filter { $0.lat != nil && $0.lon != nil }
                    .min { distanceToSection(from: loc, section: $0) < distanceToSection(from: loc, section: $1) }
                if let n = nearest {
                    let km = kmFromId(n.id)
                    let highway = highwayNameFromId(n.id)
                    nearestInfo = "目前位置約 \(highway) \(String(format: "%.1f", km)) km 附近"
                } else {
                    nearestInfo = "無法比對座標"
                }
                sections = all
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
        return loc.distance(from: CLLocation(latitude: lat, longitude: lon))
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

    func kmFromId(_ id: String) -> Double {
        let parts = id.components(separatedBy: "-")
        for (i, part) in parts.enumerated() {
            // 支援 N1, N1H, N3A, N3K 等格式
            if part.hasPrefix("N") && part.count >= 2 {
                let suffix = String(part.dropFirst())
                // 取出數字部分（忽略後綴字母如 H, A, K）
                let numStr = suffix.prefix(while: { $0.isNumber })
                if !numStr.isEmpty {
                    if i + 2 < parts.count, let km = Double(parts[i + 2]) {
                        return km
                    }
                }
            }
        }
        return Double.infinity
    }

    func highwayNameFromId(_ id: String) -> String {
        let parts = id.components(separatedBy: "-")
        for part in parts {
            if part.hasPrefix("N") && part.count >= 2 {
                let suffix = String(part.dropFirst())
                let numStr = String(suffix.prefix(while: { $0.isNumber }))
                let tag = String(suffix.drop(while: { $0.isNumber }))
                if let num = Int(numStr) {
                    switch tag {
                    case "H": return "國道\(num)號高架"
                    case "A", "K": return "國道\(num)號支線"
                    default: return "國道\(num)號"
                    }
                }
            }
        }
        return "國道"
    }

    func parseName(_ id: String, fallback: String) -> String {
        // 若 fallback 已有中文且不是 VD 開頭直接用
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
            if !foundHighway && part.hasPrefix("N") && part.count >= 2 {
                let suffix = String(part.dropFirst())
                let numStr = String(suffix.prefix(while: { $0.isNumber }))
                let tag = String(suffix.drop(while: { $0.isNumber }))
                if let num = Int(numStr), !numStr.isEmpty {
                    switch tag {
                    case "H": highway = "國道\(num)號高架"
                    case "A", "K": highway = "國道\(num)號支線"
                    default: highway = "國道\(num)號"
                    }
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
                      
