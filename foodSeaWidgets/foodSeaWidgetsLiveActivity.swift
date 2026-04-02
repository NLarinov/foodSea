import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct foodSeaWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OrderActivityAttributes.self) { context in
            LockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Заказ", systemImage: "bag.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.orderNumber)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.statusText)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    StatusProgressBar(status: context.state.status)
                }
            } compactLeading: {
                Image(systemName: "bag.fill")
            } compactTrailing: {
                Text(shortText(for: context.state.status))
                    .font(.caption2.weight(.semibold))
            } minimal: {
                Image(systemName: "bag.fill")
            }
        }
    }

    private func shortText(for status: OrderStatus) -> String {
        switch status {
        case .pending:    return "ожид."
        case .confirmed:  return "подтв."
        case .assembling: return "сборка"
        case .shipped:    return "отпр."
        case .inTransit:  return "в пути"
        case .delivered:  return "готов"
        case .cancelled:  return "отмен."
        }
    }
}

@available(iOS 16.1, *)
private struct LockScreenView: View {
    let context: ActivityViewContext<OrderActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bag.fill")
                    .foregroundStyle(.orange)
                Text("Заказ \(context.attributes.orderNumber)")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(context.state.statusText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            StatusProgressBar(status: context.state.status)
        }
        .padding()
    }
}

@available(iOS 16.1, *)
private struct StatusProgressBar: View {
    let status: OrderStatus

    var body: some View {
        let stages: [OrderStatus] = [.confirmed, .assembling, .inTransit, .delivered]
        HStack(spacing: 6) {
            ForEach(stages, id: \.self) { stage in
                Capsule()
                    .fill(isReached(stage) ? Color.green : Color.gray.opacity(0.3))
                    .frame(height: 6)
            }
        }
    }

    private func isReached(_ stage: OrderStatus) -> Bool {
        rank(of: status) >= rank(of: stage)
    }

    private func rank(of s: OrderStatus) -> Int {
        switch s {
        case .pending:    return 0
        case .confirmed:  return 1
        case .assembling: return 2
        case .shipped, .inTransit: return 3
        case .delivered:  return 4
        case .cancelled:  return -1
        }
    }
}
