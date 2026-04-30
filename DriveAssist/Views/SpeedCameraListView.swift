import SwiftUI

struct SpeedCameraListView: View {
    @State private var cameras: [SpeedCamera] = []
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
                    List(cameras) { cam in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cam.road)
                                    .font(.headline)
                                    .lineLimit(2)
                                Label("速限 \(cam.limit) km/h", systemImage: "speedometer")
                                    .font(.subheadline)
                                    .foregroundColor(limitColor(cam.limit))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .refreshable { await load() }
                }
            }
            .navigationTitle("測速照相")
            .task { await load() }
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            cameras = try await SpeedCameraService.shared.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func limitColor(_ limit: Int) -> Color {
        if limit <= 50 { return .red }
        if limit <= 70 { return .orange }
        return .green
    }
}
