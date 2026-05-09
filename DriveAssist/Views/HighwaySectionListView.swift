import SwiftUI

struct HighwaySectionListView: View {
    @State private var sections: [HighwaySection] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var directionFilter: DirectionFilter = .all

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
                    ProgressView("載入中 ...")
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

    // 依公里數由小到大排序
    func loadNearestFirst() async {
        isLoading = true
        errorMessage = nil
        do {
            let all = try await HighwayService.shared.fetchSections()
            sections = all.sorted { a, b in
                kmFromId(a.id) < kmFromId(b.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // 從 ID 解析公里數，例如 VD-N1-N-86.120-M-LOOP → 86.12
    func kmFromId(_ id: String) -> Double {
        let parts = id.components(separatedBy: "-")
        for (i, part) in parts.enumerated() {
            if part.hasPrefix("N"), Int(part.dropFirst()) != nil {
                if i + 2 < parts.count, let km = Double(parts[i + 2]) {
                    return km
                }
            }
        }
        return Double.infinity
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
