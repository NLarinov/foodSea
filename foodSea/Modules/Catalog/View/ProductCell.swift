import UIKit

final class ProductCell: UICollectionViewCell {
    static let reuseIdentifier = "ProductCell"

    var addToCartAction: (() -> Void)?
    var onQuantityChanged: ((Int) -> Void)?

    private var currentQuantity = 0

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(systemName: "photo")
        iv.tintColor = UIColor.App.secondary
        iv.clipsToBounds = true
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
        label.font = .systemFont(ofSize: Constants.UI.priceFontSize, weight: .bold)
        label.textColor = UIColor.App.pricePrimary
        return label
    }()

    private let promotionBadge: UILabel = {
        let label = UILabel()
        label.text = "Акция"
        label.font = .systemFont(ofSize: Constants.UI.badgeFontSize, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = UIColor.App.promotionBadge
        label.textAlignment = .center
        label.layer.cornerRadius = Constants.UI.smallCornerRadius
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()

    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: Constants.UI.tabBarIconSize, weight: .medium)
        button.setImage(UIImage(systemName: "cart.badge.plus", withConfiguration: config), for: .normal)
        button.tintColor = UIColor.App.primary
        return button
    }()

    private let quantityContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.App.primary
        view.layer.cornerRadius = Constants.UI.smallCornerRadius
        view.isHidden = true
        return view
    }()

    private let minusButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        button.setImage(UIImage(systemName: "minus", withConfiguration: config), for: .normal)
        button.tintColor = .white
        return button
    }()

    private let quantityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let plusButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .white
        return button
    }()

    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = UIImage(systemName: "photo")
        nameLabel.text = nil
        priceLabel.text = nil
        promotionBadge.isHidden = true
        addToCartAction = nil
        onQuantityChanged = nil
        currentQuantity = 0
        updateQuantityUI()
    }

    func configure(with product: Product, quantity: Int = 0) {
        nameLabel.text = product.name
        promotionBadge.isHidden = !product.hasPromotion

        if let lowest = product.lowestPrice {
            let formatted = priceFormatter.string(from: NSDecimalNumber(decimal: lowest)) ?? "\(lowest)"
            priceLabel.text = "\(formatted) ₽"
        } else {
            priceLabel.text = nil
        }

        currentQuantity = quantity
        updateQuantityUI()
    }

    private func updateQuantityUI() {
        let inCart = currentQuantity > 0
        addButton.isHidden = inCart
        quantityContainer.isHidden = !inCart
        quantityLabel.text = "\(currentQuantity)"
    }

    private func setupUI() {
        contentView.backgroundColor = UIColor.App.secondaryBackground
        contentView.layer.cornerRadius = Constants.UI.cornerRadius
        contentView.clipsToBounds = true

        let stack = UIStackView(arrangedSubviews: [imageView, nameLabel, priceLabel])
        stack.axis = .vertical
        stack.spacing = Constants.UI.smallPadding

        let quantityStack = UIStackView(arrangedSubviews: [minusButton, quantityLabel, plusButton])
        quantityStack.axis = .horizontal
        quantityStack.distribution = .fillEqually
        quantityStack.spacing = 0

        quantityContainer.addSubview(quantityStack)
        quantityStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            quantityStack.topAnchor.constraint(equalTo: quantityContainer.topAnchor),
            quantityStack.leadingAnchor.constraint(equalTo: quantityContainer.leadingAnchor),
            quantityStack.trailingAnchor.constraint(equalTo: quantityContainer.trailingAnchor),
            quantityStack.bottomAnchor.constraint(equalTo: quantityContainer.bottomAnchor),
        ])

        contentView.addSubview(stack)
        contentView.addSubview(promotionBadge)
        contentView.addSubview(addButton)
        contentView.addSubview(quantityContainer)

        stack.translatesAutoresizingMaskIntoConstraints = false
        promotionBadge.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        quantityContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: Constants.UI.thumbnailSize),

            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.UI.smallPadding),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.UI.smallPadding),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.UI.smallPadding),

            promotionBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.UI.smallPadding),
            promotionBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.UI.smallPadding),
            promotionBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: Constants.UI.minimumTapSize),
            promotionBadge.heightAnchor.constraint(equalToConstant: Constants.UI.largePadding),

            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.UI.smallPadding),
            addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.UI.smallPadding),
            addButton.widthAnchor.constraint(greaterThanOrEqualToConstant: Constants.UI.minimumTapSize),
            addButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.UI.minimumTapSize),

            quantityContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.UI.smallPadding),
            quantityContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.UI.smallPadding),
            quantityContainer.heightAnchor.constraint(equalToConstant: Constants.UI.minimumTapSize - Constants.UI.smallPadding),
            quantityContainer.widthAnchor.constraint(equalToConstant: Constants.UI.thumbnailSize + Constants.UI.largePadding),

            stack.bottomAnchor.constraint(lessThanOrEqualTo: addButton.topAnchor, constant: -Constants.UI.smallPadding),
        ])

        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        minusButton.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)
    }

    @objc private func addButtonTapped() {
        currentQuantity = Constants.Cart.minQuantity
        updateQuantityUI()
        addToCartAction?()
    }

    @objc private func minusTapped() {
        currentQuantity = max(0, currentQuantity - 1)
        updateQuantityUI()
        onQuantityChanged?(currentQuantity)
    }

    @objc private func plusTapped() {
        currentQuantity = min(Constants.Cart.maxQuantity, currentQuantity + 1)
        updateQuantityUI()
        onQuantityChanged?(currentQuantity)
    }
}
