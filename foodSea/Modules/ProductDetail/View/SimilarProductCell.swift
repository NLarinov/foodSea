import UIKit

final class SimilarProductCell: UICollectionViewCell {
    static let reuseIdentifier = "SimilarProductCell"
    static let cellWidth: CGFloat = 120

    var onTap: (() -> Void)?

    private let thumbnailView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.App.secondaryBackground
        view.layer.cornerRadius = Constants.UI.smallCornerRadius
        view.clipsToBounds = true
        return view
    }()

    private let thumbnailIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "photo"))
        imageView.tintColor = UIColor.App.secondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.captionFontSize)
        label.textColor = UIColor.App.label
        label.numberOfLines = 2
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize, weight: .bold)
        label.textColor = UIColor.App.pricePrimary
        return label
    }()

    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(with product: Product) {
        nameLabel.text = product.name
        if let lowestPrice = product.lowestPrice {
            let number = NSDecimalNumber(decimal: lowestPrice)
            priceLabel.text = (priceFormatter.string(from: number) ?? "0.00") + " ₽"
        } else {
            priceLabel.text = nil
        }
        thumbnailIcon.setRemoteImage(product.imageURL)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailIcon.cancelRemoteImage()
        thumbnailIcon.image = UIImage(systemName: "photo")
    }

    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        contentView.addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        onTap?()
    }

    private func setupUI() {
        contentView.backgroundColor = UIColor.App.background
        contentView.layer.cornerRadius = Constants.UI.smallCornerRadius
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.App.separator.cgColor

        thumbnailView.addSubview(thumbnailIcon)
        thumbnailIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            thumbnailIcon.topAnchor.constraint(equalTo: thumbnailView.topAnchor),
            thumbnailIcon.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor),
            thumbnailIcon.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor),
            thumbnailIcon.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor),
        ])

        let stack = UIStackView(arrangedSubviews: [thumbnailView, nameLabel, priceLabel])
        stack.axis = .vertical
        stack.spacing = Constants.UI.smallPadding / 2

        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            thumbnailView.heightAnchor.constraint(equalToConstant: Constants.UI.thumbnailSize),

            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.UI.smallPadding),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.UI.smallPadding),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.UI.smallPadding),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -Constants.UI.smallPadding),
        ])
    }
}
