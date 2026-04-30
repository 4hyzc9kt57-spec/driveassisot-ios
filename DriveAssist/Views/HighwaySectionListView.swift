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
                                Text(sec.name)
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
