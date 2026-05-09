import SwiftUI

struct ParkingListView: View {
    @StateObject private var vm = ParkingViewModel()
    @State private var showMap = false
    @State private var showDriveMode = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if vm.isLoading {
                        ProgressView("定位中 ...")
                    } else if let error = vm.errorMessage {
                        VStack(spacing: 16) {
                            Text("錯誤：\(error)").foregroundColor(.red)
                            Button("重試") {
                                Task { await vm.loadFromGPS() }
                            }
                        }
                    } else {
                        List(vm.carParks) { park in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(park.name).font(.headline)
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
                        }
                        .refreshable {
                            await vm.refresh()
                        }
                    }
                }

                // FAB 快速啟動行車模式
                Button {
                    showDriveMode = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "car.circle.fill")
                            .font(.system(size: 20))
                        Text("行車模式")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
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
            .sheet(isPresented: $showDriveMode) {
                DriveView()
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
