import SwiftUI

struct ParkingListView: View {
    @StateObject private var vm = ParkingViewModel()
    @State private var showMap = false

    var body: some View {
        NavigationView {
            Group {
                if vm.isLoading {
                    ProgressView("定位中 ...")
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
                    .refreshable {
                        await vm.refresh()
                    }
                }
            }
            .navigationTitle("附近停車場")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showMap = true
                    } label: {
                        Image(systemName: "map")
                    }
                }
            }
            .sheet(isPresented: $showMap) {
                NavigationView {
                    ParkingMapView(vm: vm)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("關閉") { showMap = false }
                            }
                        }
                }
            }
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
