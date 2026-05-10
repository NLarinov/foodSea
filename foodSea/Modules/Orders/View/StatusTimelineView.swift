import UIKit

final class StatusTimelineView: UIView {
    private var events: [StatusEvent] = []
    private var currentStatus: OrderStatus = .pending

    nonisolated override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(events: [StatusEvent], currentStatus: OrderStatus) {
        self.events = events
        self.currentStatus = currentStatus
        buildTimeline()
    }

    private func buildTimeline() {
        subviews.forEach { $0.removeFromSuperview() }

        let allStatuses = OrderStatus.allCases.filter { $0 != .cancelled && $0 != .assembling && $0 != .shipped }
        let passedStatuses = Set(events.map(\.status))
        var previousAnchor: NSLayoutYAxisAnchor = topAnchor

        for (index, status) in allStatuses.enumerated() {
            let isPassed = passedStatuses.contains(status)
            let isCurrent = status == currentStatus
            let event = events.first(where: { $0.status == status })

            let rowView = makeRow(
                status: status,
                event: event,
                isPassed: isPassed,
                isCurrent: isCurrent,
                isLast: index == allStatuses.count - 1
            )

            addSubview(rowView)
            rowView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                rowView.topAnchor.constraint(equalTo: previousAnchor, constant: index == 0 ? 0 : Constants.UI.smallPadding),
                rowView.leadingAnchor.constraint(equalTo: leadingAnchor),
                rowView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])

            previousAnchor = rowView.bottomAnchor

            if index == allStatuses.count - 1 {
                rowView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            }
        }
    }

    private func makeRow(
        status: OrderStatus,
        event: StatusEvent?,
        isPassed: Bool,
        isCurrent: Bool,
        isLast: Bool
    ) -> UIView {
        let container = UIView()

        let dot = UIView()
        let dotSize = Constants.Optimization.timelineDotSize
        dot.layer.cornerRadius = dotSize / 2
        dot.backgroundColor = isCurrent ? UIColor.App.primary
            : isPassed ? UIColor.App.success
            : UIColor.App.secondary.withAlphaComponent(0.3)

        let statusLabel = UILabel()
        statusLabel.text = status.displayName
        statusLabel.font = isCurrent
            ? .systemFont(ofSize: Constants.UI.subtitleFontSize, weight: .bold)
            : .systemFont(ofSize: Constants.UI.subtitleFontSize)
        statusLabel.textColor = isCurrent ? UIColor.App.primary
            : isPassed ? UIColor.App.label
            : UIColor.App.secondaryLabel

        let descLabel = UILabel()
        if let event {
            descLabel.text = "\(event.description) — \(Self.timeFormatter.string(from: event.timestamp))"
        }
        descLabel.font = .systemFont(ofSize: Constants.UI.captionFontSize)
        descLabel.textColor = UIColor.App.secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [statusLabel, descLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        container.addSubview(dot)
        container.addSubview(textStack)

        dot.translatesAutoresizingMaskIntoConstraints = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: dotSize),
            dot.heightAnchor.constraint(equalToConstant: dotSize),
            dot.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dot.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),

            textStack.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: Constants.UI.standardPadding),
            textStack.topAnchor.constraint(equalTo: container.topAnchor),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        if !isLast {
            let line = UIView()
            line.backgroundColor = isPassed ? UIColor.App.success : UIColor.App.secondary.withAlphaComponent(0.3)
            container.addSubview(line)
            line.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                line.widthAnchor.constraint(equalToConstant: Constants.Optimization.timelineLineWidth),
                line.centerXAnchor.constraint(equalTo: dot.centerXAnchor),
                line.topAnchor.constraint(equalTo: dot.bottomAnchor, constant: 2),
                line.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
        }

        return container
    }

    nonisolated private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM HH:mm"
        return f
    }()
}
