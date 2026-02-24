import UIKit

final class CartItemCell: UITableViewCell {
    static let reuseIdentifier = "CartItemCell"

    var onQuantityChanged: ((Int) -> Void)?
    var onDelete: (() -> Void)?

    private var currentQuantity = 1

    private let thumbnailView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(systemName: "photo")
        iv.tintColor = UIColor.App.secondary
        iv.clipsToBounds = true
        iv.layer.cornerRadius = Constants.UI.smallCornerRadius
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .medium)
        label.textColor = UIColor.App.label
        label.numberOfLines = 2
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize)
        label.textColor = UIColor.App.secondaryLabel
        return label
    }()

    private let subtotalLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.priceFontSize, weight: .bold)
        label.textColor = UIColor.App.pricePrimary
        return label
    }()

    private let decrementButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "minus.circle"), for: .normal)
        button.tintColor = UIColor.App.primary
        return button
    }()

    private let quantityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .semibold)
        label.textColor = UIColor.App.label
        label.textAlignment = .center
        return label
    }()

    private let incrementButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus.circle"), for: .normal)
        button.tintColor = UIColor.App.primary
        return button
    }()

    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "trash"), for: .normal)
        button.tintColor = UIColor.App.error
        return button
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
        thumbnailView.image = UIImage(systemName: "photo")
        nameLabel.text = nil
        priceLabel.text = nil
        subtotalLabel.text = nil
        quantityLabel.text = nil
        onQuantityChanged = nil
        onDelete = nil
    }

    func configure(with item: CartItem) {
        currentQuantity = item.quantity
        nameLabel.text = item.product.name
        quantityLabel.text = "\(item.quantity)"

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        if let lowest = item.product.lowestPrice {
            let formatted = formatter.string(from: NSDecimalNumber(decimal: lowest)) ?? "\(lowest)"
            priceLabel.text = "\(formatted) ₽ / шт"
        }

        if let subtotal = item.subtotal {
            let formatted = formatter.string(from: NSDecimalNumber(decimal: subtotal)) ?? "\(subtotal)"
            subtotalLabel.text = "\(formatted) ₽"
        }
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = UIColor.App.background

        let infoStack = UIStackView(arrangedSubviews: [nameLabel, priceLabel, subtotalLabel])
        infoStack.axis = .vertical
        infoStack.spacing = Constants.UI.smallPadding / 2

        let quantityStack = UIStackView(arrangedSubviews: [decrementButton, quantityLabel, incrementButton])
        quantityStack.axis = .horizontal
        quantityStack.spacing = Constants.UI.smallPadding
        quantityStack.alignment = .center

        quantityLabel.setSize(width: Constants.UI.minimumTapSize)
        decrementButton.setSize(width: Constants.UI.minimumTapSize, height: Constants.UI.minimumTapSize)
        incrementButton.setSize(width: Constants.UI.minimumTapSize, height: Constants.UI.minimumTapSize)
        deleteButton.setSize(width: Constants.UI.minimumTapSize, height: Constants.UI.minimumTapSize)

        let controlsStack = UIStackView(arrangedSubviews: [quantityStack, deleteButton])
        controlsStack.axis = .horizontal
        controlsStack.spacing = Constants.UI.smallPadding
        controlsStack.alignment = .center

        let rightStack = UIStackView(arrangedSubviews: [infoStack, controlsStack])
        rightStack.axis = .vertical
        rightStack.spacing = Constants.UI.smallPadding

        let mainStack = UIStackView(arrangedSubviews: [thumbnailView, rightStack])
        mainStack.axis = .horizontal
        mainStack.spacing = Constants.UI.standardPadding
        mainStack.alignment = .center

        thumbnailView.setSize(width: Constants.UI.thumbnailSize, height: Constants.UI.thumbnailSize)

        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.UI.smallPadding),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.UI.standardPadding),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.UI.standardPadding),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.UI.smallPadding),
        ])

        decrementButton.addTarget(self, action: #selector(decrementTapped), for: .touchUpInside)
        incrementButton.addTarget(self, action: #selector(incrementTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }

    @objc private func decrementTapped() {
        currentQuantity -= 1
        onQuantityChanged?(currentQuantity)
    }

    @objc private func incrementTapped() {
        guard currentQuantity < Constants.Cart.maxQuantity else { return }
        currentQuantity += 1
        onQuantityChanged?(currentQuantity)
    }

    @objc private func deleteTapped() {
        onDelete?()
    }
}
