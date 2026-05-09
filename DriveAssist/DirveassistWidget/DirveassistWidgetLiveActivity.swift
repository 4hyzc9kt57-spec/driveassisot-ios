import ActivityKit
import WidgetKit
import SwiftUI

struct DirveassistWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DriveAssistAttributes.self) { context in
            LockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("速限")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(context.state.speedLimit > 0 ? "\(context.state.speedLimit)" : "--")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(context.state.isWarning ? .red : .white)
                        if context.state.cameraDistance > 0 {
                            Text("測速 \(context.state.cameraDistance)m")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("車速")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("\(context.state.currentSpeed)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("km/h")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        if context.state.cameraLimit > 0 {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.orange)
                                Text("測速 \(context.state.cameraLimit) km/h")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                        }
                        Divider().background(Color.gray.opacity(0.5))
                        ForEach(context.state.parkingSpots.prefix(3), id: \.name) { spot in
                            HStack(spacing: 6) {
                                Image(systemName: "parkingsign.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(spot.name)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(spot.dist)m")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(spot.avail)格")
                                    .font(.caption2)
                                    .foregroundColor(spot.avail > 10 ? .green : spot.avail > 0 ? .orange : .red)
                                Link(destination: URL(string: "comgooglemaps://?daddr=\(spot.lat),\(spot.lon)&directionsmode=driving")!) {
                                    Text("去")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.8))
                                        .cornerRadius(4)
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                        if context.state.parkingSpots.isEmpty {
                            HStack {
                                Image(systemName: "parkingsign.circle")
                                    .foregroundColor(.gray)
                                Text("無附近停車場資料")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } compactLeading: {
                HStack(spacing: 3) {
                    Circle()
                        .fill(context.state.isWarning ? Color.red : context.state.speedLimit > 0 ? Color.yellow : Color.green)
                        .frame(width: 8, height: 8)
                    if context.state.speedLimit > 0 {
                        Text("\(context.state.speedLimit)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(context.state.isWarning ? .red : .white)
                    }
                }
            } compactTrailing: {
                HStack(spacing: 2) {
                    if context.state.cameraLimit > 0 {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                    }
                    Text("\(context.state.currentSpeed)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            } minimal: {
                Circle()
                    .fill(context.state.isWarning ? Color.red : context.state.speedLimit > 0 ? Color.yellow : Color.green)
                    .frame(width: 10, height: 10)
            }
            .widgetURL(URL(string: "driveassist://island"))
            .keylineTint(context.state.isWarning ? .red : .green)
        }
    }
}

struct LockScreenView: View {
    let context: ActivityViewContext<DriveAssistAttributes>

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text("速限")
                    .font(.caption2)
                    .foregroundColor(.gray)
                ZStack {
                    Circle()
                        .stroke(context.state.isWarning ? Color.red : Color.white, lineWidth: 3)
                        .frame(width: 52, height: 52)
                    Text(context.state.speedLimit > 0 ? "\(context.state.speedLimit)" : "--")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(context.state.isWarning ? .red : .white)
                }
                if context.state.cameraDistance > 0 {
                    Text("\(context.state.cameraDistance)m")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            Divider().background(Color.gray)
            VStack(alignment: .leading, spacing: 3) {
                ForEach(context.state.parkingSpots.prefix(3), id: \.name) { spot in
                    HStack(spacing: 4) {
                        Image(systemName: "parkingsign.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 10))
                        Text(spot.name)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer()
                        Text("\(spot.avail)格")
                            .font(.caption2)
                            .foregroundColor(spot.avail > 10 ? .green : spot.avail > 0 ? .orange : .red)
                    }
                }
                if context.state.parkingSpots.isEmpty {
                    Text("無附近停車場")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            VStack(spacing: 2) {
                Text("km/h")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text("\(context.state.currentSpeed)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(12)
    }
}
