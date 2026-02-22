import UIKit

final class PriceComparisonCell: UITableViewCell {
    static let reuseIdentifier = "PriceComparisonCell"

    private let storeNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .medium)
        label.textColor = UIColor.App.label
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.priceFontSize, weight: .bold)
        label.textColor = UIColor.App.pricePrimary
        return label
    }()

    private let originalPriceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.captionFontSize)
        label.textColor = UIColor.App.priceOriginal
        return label
    }()

    private let deliveryFeeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.captionFontSize)
        label.textColor = UIColor.App.secondaryLabel
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

    private let cheapestIndicator: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        imageView.tintColor = UIColor.App.success
        imageView.isHidden = true
        return imageView
    }()

    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(with entry: PriceEntry, isCheapest: Bool) {
        storeNameLabel.text = entry.store.name
        priceLabel.text = formatPrice(entry.price)

        if let originalPrice = entry.originalPrice, entry.hasPromotion {
            let attributed = NSAttributedString(
                string: formatPrice(originalPrice),
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
            )
            originalPriceLabel.attributedText = attributed
            originalPriceLabel.isHidden = false
        } else {
            originalPriceLabel.isHidden = true
        }

        promotionBadge.isHidden = !entry.hasPromotion
        cheapestIndicator.isHidden = !isCheapest

        deliveryFeeLabel.text = "Доставка: \(formatPrice(entry.deliveryFee))"
    }

    private func formatPrice(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        return (priceFormatter.string(from: number) ?? "0.00") + " ₽"
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = UIColor.App.background

        let priceStack = UIStackView(arrangedSubviews: [priceLabel, originalPriceLabel])
        priceStack.axis = .horizontal
        priceStack.spacing = Constants.UI.smallPadding

        let topRow = UIStackView(arrangedSubviews: [storeNameLabel, cheapestIndicator])
        topRow.axis = .horizontal
        topRow.spacing = Constants.UI.smallPadding

        let infoStack = UIStackView(arrangedSubviews: [topRow, priceStack, deliveryFeeLabel])
        infoStack.axis = .vertical
        infoStack.spacing = Constants.UI.smallPadding / 2

        let mainStack = UIStackView(arrangedSubviews: [infoStack, promotionBadge])
        mainStack.axis = .horizontal
        mainStack.alignment = .center
        mainStack.spacing = Constants.UI.smallPadding

        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        cheapestIndicator.setSize(width: Constants.UI.tabBarIconSize, height: Constants.UI.tabBarIconSize)

        let badgePadding = Constants.UI.smallPadding
        promotionBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            promotionBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: Constants.UI.minimumTapSize),
            promotionBadge.heightAnchor.constraint(equalToConstant: badgePadding * 3),
        ])

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.UI.smallPadding),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.UI.standardPadding),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.UI.standardPadding),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.UI.smallPadding),
        ])
    }
}
