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
        }
    }
}
