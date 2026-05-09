import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ParkingListView()
                .tabItem {
                    Label("停車場", systemImage: "parkingsign.circle")
                }
            SpeedCameraListView()
                .tabItem {
                    Label("測速照相", systemImage: "speedometer")
                }
            HighwaySectionListView()
                .tabItem {
                    Label("高速公路", systemImage: "road.lanes")
                }
            DriveView()
                .tabItem {
                    Label("行車模式", systemImage: "car.circle")
                }
        }
    }
}

struct DriveView: View {
    @StateObject private var vm = DriveViewModel()
    @StateObject private var manager = LiveActivityManager.shared
    @AppStorage("autoStartEnabled") private var autoStartEnabled = false

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(vm.isActive ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 160, height: 160)
                    VStack(spacing: 8) {
                        Image(systemName: vm.isActive ? "car.circle.fill" : "car.circle")
                            .font(.system(size: 64))
                            .foregroundColor(vm.isActive ? .green : .gray)
                        Text(vm.isActive ? "行車中" : "已停止")
                            .font(.headline)
                            .foregroundColor(vm.isActive ? .green : .gray)
                    }
                }

                if vm.isActive {
                    VStack(spacing: 8) {
                        HStack(spacing: 24) {
                            VStack {
                                Text("\(vm.currentSpeed)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("km/h")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if let cam = vm.nearestCamera {
                                VStack {
                                    Text("\(cam.limit)")
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundColor(.orange)
                                    Text("速限")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        if let cam = vm.nearestCamera {
                            Text("📷 \(cam.road)")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .lineLimit(1)
                        }
                    }
                }

                Button {
                    if vm.isActive {
                        Task { await vm.stop() }
                    } else {
                        vm.start()
                    }
                } label: {
                    Text(vm.isActive ? "停止行車模式" : "啟動行車模式")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(vm.isActive ? Color.red : Color.green)
                        .cornerRadius(16)
                        .padding(.horizontal, 32)
                }

                if vm.isActive {
                    Text("動態島已啟動\n速限與停車資訊將即時顯示")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // 自動啟動 Toggle
                Divider().padding(.horizontal, 32)

                Toggle(isOn: $autoStartEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("車速 >10 km/h 自動啟動")
                            .font(.subheadline)
                        Text("偵測到行駛時自動進入行車模式")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 32)
                .onChange(of: autoStartEnabled) { enabled in
                    if enabled && !vm.isActive {
                        vm.startAutoMonitor()
                    }
                }

                Spacer()
            }
            .navigationTitle("行車助手")
            .onAppear {
                if autoStartEnabled && !vm.isActive {
                    vm.startAutoMonitor()
                }
            }
        }
    }
}
