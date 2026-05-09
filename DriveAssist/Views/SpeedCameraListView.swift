import SwiftUI

struct SpeedCameraListView: View {
    @StateObject private var vm = SpeedCameraViewModel()

    var body: some View {
        NavigationView {
            Group {
                if vm.isLoading {
                    ProgressView("定位中 ...")
                } else if let error = vm.errorMessage {
                    VStack(spacing: 16) {
                        Text(error).foregroundColor(.secondary).multilineTextAlignment(.center)
                        Button("重試") {
                            Task { await vm.loadFromGPS() }
                        }
                    }
                    .padding()
                } else {
                    List(vm.cameras) { cam in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cam.road)
                                    .font(.headline)
                                    .lineLimit(2)
                                HStack(spacing: 8) {
                                    Label("速限 \(cam.limit) km/h", systemImage: "speedometer")
                                        .font(.subheadline)
                                        .foregroundColor(limitColor(cam.limit))
                                    if let dist = cam.dist {
                                        Text("\(dist) m")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .refreshable { await vm.refresh() }
                }
            }
            .navigationTitle("測速照相")
            .task { await vm.loadFromGPS() }
        }
    }

    func limitColor(_ limit: Int) -> Color {
        if limit <= 50 { return .red }
        if limit <= 70 { return .orange }
        return .green
    }
}
