import SwiftUI

struct HighwaySectionListView: View {
    @State private var sections: [HighwaySection] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("載入中 ...")
                } else if let error = errorMessage {
                    Text("錯誤：\(error)").foregroundColor(.red)
                } else {
                    List(sections) { sec in
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
            .navigationTitle("高速公路路況")
            .task { await load() }
        }
    }

    func parseName(_ id: String, fallback: String) -> String {
        // 若 name 已有中文且不是 VD 開頭直接用
        if !fallback.hasPrefix("VD") && fallback.range(of: "[\\u4e00-\\u9fff]", options: .regularExpression) != nil {
            return fallback
        }

        // ID 格式：VD-N1-N-86.120-M-LOOP
        // parts[0]=VD, parts[1]=N1, parts[2]=N/S, parts[3]=86.120
        let parts = id.components(separatedBy: "-")
        guard parts.count >= 3 else { return fallback }

        // 找國道編號（格式 N1, N3, N5...）
        var highway = ""
        var direction = ""
        var km = ""
        var foundHighway = false

        for (i, part) in parts.enumerated() {
            // 國道編號：N 開頭後接數字，長度 2-3
            if !foundHighway && part.count >= 2 && part.hasPrefix("N") {
                let numStr = String(part.dropFirst())
                if let num = Int(numStr) {
                    highway = "國道\(num)號"
                    foundHighway = true
                    // 下一個 part 是方向
                    if i + 1 < parts.count {
                        switch parts[i + 1] {
                        case "N": direction = "北上"
                        case "S": direction = "南下"
                        case "E": direction = "東行"
                        case "W": direction = "西行"
                        default: break
                        }
                    }
                    // 再下一個是公里數
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
