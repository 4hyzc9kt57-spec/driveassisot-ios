import SwiftUI

struct ContentView: View {
    @StateObject private var liveActivityManager = LiveActivityManager.shared

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
    @StateObject private var manager = LiveActivityManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()

                // 狀態圖示
                ZStack {
                    Circle()
                        .fill(manager.isRunning ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 160, height: 160)
                    VStack(spacing: 8) {
                        Image(systemName: manager.isRunning ? "car.circle.fill" : "car.circle")
                            .font(.system(size: 64))
                            .foregroundColor(manager.isRunning ? .green : .gray)
                        Text(manager.isRunning ? "行車中" : "已停止")
                            .font(.headline)
                            .foregroundColor(manager.isRunning ? .green : .gray)
                    }
                }

                // 啟動/停止按鈕
                Button {
                    if manager.isRunning {
                        Task { await manager.stop() }
                    } else {
                        manager.start()
                    }
                } label: {
                    Text(manager.isRunning ? "停止行車模式" : "啟動行車模式")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(manager.isRunning ? Color.red : Color.green)
                        .cornerRadius(16)
                        .padding(.horizontal, 32)
                }

                if manager.isRunning {
                    Text("動態島已啟動\n速限與停車資訊將即時顯示")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .navigationTitle("行車助手")
        }
    }
}
