import UIKit

final class OrderCell: UITableViewCell {
    static let reuseIdentifier = "OrderCell"

    private let orderNumberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .semibold)
        label.textColor = UIColor.App.label
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.captionFontSize)
        label.textColor = UIColor.App.secondaryLabel
        return label
    }()

    private let statusBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.captionFontSize, weight: .medium)
        label.textAlignment = .center
        label.layer.cornerRadius = Constants.UI.smallCornerRadius
        label.clipsToBounds = true
        return label
    }()

    private let totalLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.priceFontSize, weight: .bold)
        label.textColor = UIColor.App.pricePrimary
        return label
    }()

    private let storesLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.captionFontSize)
        label.textColor = UIColor.App.secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        orderNumberLabel.text = nil
        dateLabel.text = nil
        statusBadge.text = nil
        totalLabel.text = nil
        storesLabel.text = nil
    }

    func configure(with order: Order) {
        orderNumberLabel.text = order.orderNumber
        dateLabel.text = Self.dateFormatter.string(from: order.createdAt)

        statusBadge.text = " \(order.status.displayName) "
        applyStatusColor(order.status)

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let totalStr = formatter.string(from: NSDecimalNumber(decimal: order.totalCost)) ?? "\(order.totalCost)"
        totalLabel.text = "\(totalStr) ₽"

        storesLabel.text = order.stores.map(\.name).joined(separator: ", ")
    }

    private func applyStatusColor(_ status: OrderStatus) {
        let color: UIColor
        switch status {
        case .pending: color = UIColor.App.warning
        case .confirmed: color = UIColor.App.primary
        case .assembling: color = UIColor.App.accent
        case .shipped, .inTransit: color = UIColor.App.primary
        case .delivered: color = UIColor.App.success
        case .cancelled: color = UIColor.App.error
        }
        statusBadge.textColor = color
        statusBadge.backgroundColor = color.withAlphaComponent(0.1)
    }

    nonisolated private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy HH:mm"
        return f
    }()

    private func setupUI() {
        accessoryType = .disclosureIndicator
        backgroundColor = UIColor.App.background

        let topRow = UIStackView(arrangedSubviews: [orderNumberLabel, UIView(), statusBadge])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = Constants.UI.smallPadding

        let bottomRow = UIStackView(arrangedSubviews: [storesLabel, UIView(), totalLabel])
        bottomRow.axis = .horizontal
        bottomRow.alignment = .center
        bottomRow.spacing = Constants.UI.smallPadding

        let mainStack = UIStackView(arrangedSubviews: [topRow, dateLabel, bottomRow])
        mainStack.axis = .vertical
        mainStack.spacing = Constants.UI.smallPadding

        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.UI.standardPadding),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.UI.standardPadding),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.UI.standardPadding),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.UI.standardPadding),
        ])
    }
}
