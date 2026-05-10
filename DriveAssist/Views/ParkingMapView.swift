import SwiftUI
import MapKit

struct ParkingMapView: View {
    @ObservedObject var vm: ParkingViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.0478, longitude: 121.5318),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var isCenteredOnUser = true
    @State private var hasInitialized = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                userTrackingMode: .none,
                annotationItems: vm.carParks) { park in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: park.lat, longitude: park.lon
                )) {
                    VStack(spacing: 2) {
                        ZStack {
                            Circle()
                                .fill(availColor(park.avail ?? 0))
                                .frame(width: 36, height: 36)
                            Image(systemName: "car.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                        }
                        Text(park.name)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .background(Color.white.opacity(0.85))
                            .cornerRadius(4)
                            .lineLimit(1)
                    }
                }
            }
            .onChange(of: vm.locationManager.location) { loc in
                guard let loc = loc else { return }
                if !hasInitialized {
                    hasInitialized = true
                    withAnimation {
                        region.center = loc.coordinate
                        region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    }
                    isCenteredOnUser = true
                } else if isCenteredOnUser {
                    withAnimation {
                        region.center = loc.coordinate
                    }
                }
            }

            // 定位按鈕 — 獨立於地圖之外，確保不被蓋住
            Button {
                if let loc = vm.locationManager.location {
                    withAnimation {
                        region.center = loc.coordinate
                        region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    }
                    isCenteredOnUser = true
                }
            } label: {
                Image(systemName: isCenteredOnUser ? "location.fill" : "location")
                    .font(.system(size: 18))
                    .foregroundColor(isCenteredOnUser ? .blue : .primary)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 80)  // 避免被 safe area 蓋住
            .zIndex(1)  // 確保在地圖上層
        }
        .navigationTitle("停車場地圖")
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            // 優先用 locationManager 現有位置
            if let loc = vm.locationManager.location {
                region.center = loc.coordinate
                region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                hasInitialized = true
                isCenteredOnUser = true
            }
        }
    }

    func availColor(_ avail: Int) -> Color {
        if avail == 0 { return .red }
        if avail < 20 { return .orange }
        return .green
    }
}
