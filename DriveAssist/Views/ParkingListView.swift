import SwiftUI

struct ParkingListView: View {
    @StateObject private var vm = ParkingViewModel()

    var body: some View {
        NavigationView {
            Group {
                if vm.isLoading {
                    ProgressView("定位中...")
                } else if let error = vm.errorMessage {
                    Text("錯誤：\(error)").foregroundColor(.red)
                } else {
                    List(vm.carParks) { park in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(park.name)
                                    .font(.headline)
                                HStack(spacing: 8) {
                                    if let avail = park.avail {
                                        Label("\(avail) 格可用", systemImage: "car.fill")
                                            .font(.subheadline)
                                            .foregroundColor(availColor(avail))
                                    }
                                    if let dist = park.dist {
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
                }
            }
            .navigationTitle("附近停車場")
            .task {
                await vm.loadFromGPS()
            }
        }
    }

    func availColor(_ avail: Int) -> Color {
        if avail == 0 { return .red }
        if avail < 20 { return .orange }
        return .green
    }
}
