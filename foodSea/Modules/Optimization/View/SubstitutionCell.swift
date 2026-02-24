import UIKit

final class SubstitutionCell: UITableViewCell {
    static let reuseIdentifier = "SubstitutionCell"

    var onAccept: (() -> Void)?
    var onReject: (() -> Void)?

    private let originalLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize)
        label.textColor = UIColor.App.secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let arrowImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "arrow.right")
        iv.tintColor = UIColor.App.primary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let alternativeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize, weight: .medium)
        label.textColor = UIColor.App.label
        label.numberOfLines = 0
        return label
    }()

    private let priceDiffLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.captionFontSize, weight: .semibold)
        label.textAlignment = .center
        label.layer.cornerRadius = Constants.UI.smallCornerRadius
        label.clipsToBounds = true
        return label
    }()

    private let acceptButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = Constants.Optimization.acceptButton
        config.baseBackgroundColor = UIColor.App.success
        config.cornerStyle = .capsule
        config.buttonSize = .small
        let button = UIButton(configuration: config)
        return button
    }()

    private let rejectButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = Constants.Optimization.rejectButton
        config.baseBackgroundColor = UIColor.App.secondary
        config.cornerStyle = .capsule
        config.buttonSize = .small
        let button = UIButton(configuration: config)
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
        originalLabel.text = nil
        alternativeLabel.text = nil
        priceDiffLabel.text = nil
        onAccept = nil
        onReject = nil
    }

    func configure(with substitution: Substitution) {
        originalLabel.text = substitution.original.name
        alternativeLabel.text = substitution.alternative.name

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        let diffStr = formatter.string(from: NSDecimalNumber(decimal: substitution.priceDifference)) ?? "\(substitution.priceDifference)"
        if substitution.priceDifference > 0 {
            priceDiffLabel.text = " −\(diffStr) ₽ "
            priceDiffLabel.textColor = UIColor.App.success
            priceDiffLabel.backgroundColor = UIColor.App.success.withAlphaComponent(0.1)
        } else {
            priceDiffLabel.text = " +\(diffStr) ₽ "
            priceDiffLabel.textColor = UIColor.App.error
            priceDiffLabel.backgroundColor = UIColor.App.error.withAlphaComponent(0.1)
        }

        updateToggleState(isAccepted: substitution.isAccepted)
    }

    private func updateToggleState(isAccepted: Bool) {
        acceptButton.isHidden = isAccepted
        rejectButton.isHidden = !isAccepted
    }

    @objc private func acceptTapped() {
        onAccept?()
        updateToggleState(isAccepted: true)
    }

    @objc private func rejectTapped() {
        onReject?()
        updateToggleState(isAccepted: false)
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = UIColor.App.background

        arrowImageView.setSize(width: Constants.UI.tabBarIconSize, height: Constants.UI.tabBarIconSize)

        let productRow = UIStackView(arrangedSubviews: [originalLabel, arrowImageView, alternativeLabel])
        productRow.axis = .horizontal
        productRow.spacing = Constants.UI.smallPadding
        productRow.alignment = .center

        let buttonsRow = UIStackView(arrangedSubviews: [priceDiffLabel, UIView(), acceptButton, rejectButton])
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = Constants.UI.smallPadding
        buttonsRow.alignment = .center

        let mainStack = UIStackView(arrangedSubviews: [productRow, buttonsRow])
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

        acceptButton.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        rejectButton.addTarget(self, action: #selector(rejectTapped), for: .touchUpInside)
    }
}
