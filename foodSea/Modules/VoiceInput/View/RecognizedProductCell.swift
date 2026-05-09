import UIKit

final class RecognizedProductCell: UITableViewCell {
    static let reuseIdentifier = "RecognizedProductCell"

    var onQuantityChanged: ((Int) -> Void)?
    var onRemove: (() -> Void)?

    private var currentQuantity = 1
    private var currentUnit: String = Constants.Voice.unitFallback

    private let productImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = UIColor.App.secondaryBackground
        iv.layer.cornerRadius = Constants.UI.smallCornerRadius
        iv.clipsToBounds = true
        iv.image = UIImage(systemName: "cart")
        iv.tintColor = UIColor.App.secondaryLabel
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize, weight: .medium)
        label.textColor = UIColor.App.label
        label.numberOfLines = 2
        return label
    }()

    private let confidenceBar: UIProgressView = {
        let bar = UIProgressView(progressViewStyle: .default)
        bar.trackTintColor = UIColor.App.secondaryBackground
        return bar
    }()

    private let confidenceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.captionFontSize)
        label.textColor = UIColor.App.secondaryLabel
        return label
    }()

    private let stepper: UIStepper = {
        let stepper = UIStepper()
        stepper.minimumValue = Double(Constants.Cart.minQuantity)
        stepper.maximumValue = Double(Constants.Cart.maxQuantity)
        stepper.stepValue = 1
        return stepper
    }()

    private let quantityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize, weight: .semibold)
        label.textColor = UIColor.App.label
        label.textAlignment = .center
        return label
    }()

    private let removeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = UIColor.App.secondaryLabel
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

    func configure(with item: RecognizedProduct) {
        nameLabel.text = item.product.name
        currentQuantity = item.quantity
        currentUnit = item.unit
        quantityLabel.text = "\(item.quantity) \(item.unit)"
        stepper.value = Double(item.quantity)

        let confidence = Float(item.confidence)
        confidenceBar.setProgress(confidence, animated: false)
        confidenceLabel.text = "\(Int(item.confidence * 100))%"

        if item.confidence >= 0.9 {
            confidenceBar.progressTintColor = UIColor.App.success
        } else if item.confidence >= 0.8 {
            confidenceBar.progressTintColor = UIColor.App.accent
        } else {
            confidenceBar.progressTintColor = UIColor.App.warning
        }
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = UIColor.App.background

        let confidenceStack = UIStackView(arrangedSubviews: [confidenceBar, confidenceLabel])
        confidenceStack.axis = .horizontal
        confidenceStack.spacing = Constants.UI.smallPadding
        confidenceStack.alignment = .center
        confidenceBar.setSize(height: Constants.Voice.confidenceBarHeight)

        let quantityStack = UIStackView(arrangedSubviews: [stepper, quantityLabel])
        quantityStack.axis = .horizontal
        quantityStack.spacing = Constants.UI.smallPadding
        quantityStack.alignment = .center

        let textStack = UIStackView(arrangedSubviews: [nameLabel, confidenceStack, quantityStack])
        textStack.axis = .vertical
        textStack.spacing = Constants.UI.smallPadding

        let mainStack = UIStackView(arrangedSubviews: [productImageView, textStack, removeButton])
        mainStack.axis = .horizontal
        mainStack.spacing = Constants.UI.smallPadding
        mainStack.alignment = .center

        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.UI.smallPadding),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.UI.standardPadding),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.UI.standardPadding),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.UI.smallPadding),
        ])

        productImageView.setSize(width: Constants.UI.thumbnailSize, height: Constants.UI.thumbnailSize)
        removeButton.setSize(width: Constants.UI.minimumTapSize, height: Constants.UI.minimumTapSize)

        stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
        removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
    }

    @objc private func stepperChanged() {
        let quantity = Int(stepper.value)
        currentQuantity = quantity
        quantityLabel.text = "\(quantity) \(currentUnit)"
        onQuantityChanged?(quantity)
    }

    @objc private func removeTapped() {
        onRemove?()
    }
}
