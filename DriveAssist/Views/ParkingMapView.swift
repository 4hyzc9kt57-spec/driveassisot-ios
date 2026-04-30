import SwiftUI
import MapKit

struct ParkingMapView: View {
    @ObservedObject var vm: ParkingViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.0478, longitude: 121.5318),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: vm.carParks) { park in
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
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("停車場地圖")
        .onAppear {
            if let loc = vm.locationManager.location {
                region.center = loc.coordinate
            }
        }
    }

    func availColor(_ avail: Int) -> Color {
        if avail == 0 { return .red }
        if avail < 20 { return .orange }
        return .green
    }
}
