import UIKit

final class StoreOrderCell: UITableViewCell {
    static let reuseIdentifier = "StoreOrderCell"

    private var isExpanded = true

    private let storeIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "storefront")
        iv.tintColor = UIColor.App.primary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let storeNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .semibold)
        label.textColor = UIColor.App.label
        return label
    }()

    private let subtotalLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize, weight: .medium)
        label.textColor = UIColor.App.pricePrimary
        return label
    }()

    private let deliveryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.captionFontSize)
        label.textColor = UIColor.App.secondaryLabel
        return label
    }()

    private let chevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.up")
        iv.tintColor = UIColor.App.secondaryLabel
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let itemsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Constants.UI.smallPadding
        return stack
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
        storeNameLabel.text = nil
        subtotalLabel.text = nil
        deliveryLabel.text = nil
        itemsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        isExpanded = true
        chevronImageView.image = UIImage(systemName: "chevron.up")
    }

    func configure(with storeOrder: StoreOrder) {
        storeNameLabel.text = storeOrder.store.name

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        let subtotalStr = formatter.string(from: NSDecimalNumber(decimal: storeOrder.subtotal)) ?? "\(storeOrder.subtotal)"
        subtotalLabel.text = "\(subtotalStr) ₽"

        if storeOrder.deliveryFee == 0 {
            deliveryLabel.text = "Доставка: \(Constants.Optimization.deliveryFreeLabel)"
            deliveryLabel.textColor = UIColor.App.success
        } else {
            let deliveryStr = formatter.string(from: NSDecimalNumber(decimal: storeOrder.deliveryFee)) ?? "\(storeOrder.deliveryFee)"
            deliveryLabel.text = "Доставка: \(deliveryStr) ₽"
            deliveryLabel.textColor = UIColor.App.secondaryLabel
        }

        itemsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for item in storeOrder.items {
            let row = makeItemRow(item)
            itemsStack.addArrangedSubview(row)
        }
    }

    func toggleExpansion() {
        isExpanded.toggle()
        itemsStack.isHidden = !isExpanded
        let imageName = isExpanded ? "chevron.up" : "chevron.down"
        UIView.animate(withDuration: Constants.Animation.defaultDuration) {
            self.chevronImageView.image = UIImage(systemName: imageName)
        }
    }

    private func makeItemRow(_ item: OptimizedItem) -> UIView {
        let nameLabel = UILabel()
        nameLabel.text = "\(item.product.name) × \(item.quantity)"
        nameLabel.font = .systemFont(ofSize: Constants.UI.subtitleFontSize)
        nameLabel.textColor = UIColor.App.label
        nameLabel.numberOfLines = 0

        let priceLabel = UILabel()
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let total = item.price * Decimal(item.quantity)
        let priceStr = formatter.string(from: NSDecimalNumber(decimal: total)) ?? "\(total)"
        priceLabel.text = "\(priceStr) ₽"
        priceLabel.font = .systemFont(ofSize: Constants.UI.subtitleFontSize, weight: .medium)
        priceLabel.textColor = UIColor.App.pricePrimary
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [nameLabel, priceLabel])
        stack.axis = .horizontal
        stack.spacing = Constants.UI.smallPadding
        stack.alignment = .center
        return stack
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = UIColor.App.background

        let iconContainer = UIView()
        iconContainer.addSubview(storeIconView)
        storeIconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            storeIconView.widthAnchor.constraint(equalToConstant: Constants.UI.tabBarIconSize),
            storeIconView.heightAnchor.constraint(equalToConstant: Constants.UI.tabBarIconSize),
            storeIconView.topAnchor.constraint(equalTo: iconContainer.topAnchor),
            storeIconView.leadingAnchor.constraint(equalTo: iconContainer.leadingAnchor),
            storeIconView.trailingAnchor.constraint(equalTo: iconContainer.trailingAnchor),
            storeIconView.bottomAnchor.constraint(lessThanOrEqualTo: iconContainer.bottomAnchor),
        ])

        let headerRight = UIStackView(arrangedSubviews: [subtotalLabel, deliveryLabel])
        headerRight.axis = .vertical
        headerRight.spacing = 2
        headerRight.alignment = .trailing

        let titleAndChevron = UIStackView(arrangedSubviews: [storeNameLabel, chevronImageView])
        titleAndChevron.axis = .horizontal
        titleAndChevron.spacing = Constants.UI.smallPadding
        chevronImageView.setSize(width: Constants.UI.tabBarIconSize, height: Constants.UI.tabBarIconSize)

        let headerTopRow = UIStackView(arrangedSubviews: [iconContainer, titleAndChevron, UIView(), headerRight])
        headerTopRow.axis = .horizontal
        headerTopRow.spacing = Constants.UI.smallPadding
        headerTopRow.alignment = .center

        let separator = UIView()
        separator.backgroundColor = UIColor.App.separator
        separator.setSize(height: 1)

        let mainStack = UIStackView(arrangedSubviews: [headerTopRow, separator, itemsStack])
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
