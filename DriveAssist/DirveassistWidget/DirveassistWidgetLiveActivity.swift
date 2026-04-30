import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity UI
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
                    }
                    .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "parkingsign.circle.fill")
                            .foregroundColor(.green)
                        Text(context.state.nearestParking.isEmpty ? "無附近停車場" : context.state.nearestParking)
                            .font(.caption)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer()
                        if context.state.parkingAvail > 0 {
                            Text("\(context.state.parkingAvail) 格")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                }
            } compactLeading: {
                Text(context.state.speedLimit > 0 ? "\(context.state.speedLimit)" : "🚗")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(context.state.isWarning ? .red : .white)
            } compactTrailing: {
                Text("\(context.state.currentSpeed)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            } minimal: {
                Image(systemName: context.state.isWarning ? "exclamationmark.triangle.fill" : "speedometer")
                    .foregroundColor(context.state.isWarning ? .red : .white)
            }
            .widgetURL(URL(string: "driveassist://island"))
            .keylineTint(context.state.isWarning ? .red : .green)
        }
    }
}

// MARK: - 鎖定畫面 View
struct LockScreenView: View {
    let context: ActivityViewContext<DriveAssistAttributes>

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text("速限")
                    .font(.caption2)
                    .foregroundColor(.gray)
                ZStack {
                    Circle()
                        .stroke(context.state.isWarning ? Color.red : Color.white, lineWidth: 3)
                        .frame(width: 56, height: 56)
                    Text(context.state.speedLimit > 0 ? "\(context.state.speedLimit)" : "--")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(context.state.isWarning ? .red : .white)
                }
            }
            Divider().background(Color.gray)
            VStack(alignment: .leading, spacing: 4) {
                Label("附近停車", systemImage: "parkingsign.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(context.state.nearestParking.isEmpty ? "無資料" : context.state.nearestParking)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                if context.state.parkingAvail > 0 {
                    Text("剩餘 \(context.state.parkingAvail) 格")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            Spacer()
            VStack(spacing: 2) {
                Text("km/h")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text("\(context.state.currentSpeed)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(16)
    }
}
