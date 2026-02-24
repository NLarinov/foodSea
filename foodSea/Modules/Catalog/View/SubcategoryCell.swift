import UIKit

final class SubcategoryCell: UICollectionViewCell {
    static let reuseIdentifier = "SubcategoryCell"

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor.App.primary
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.captionFontSize, weight: .medium)
        label.textColor = UIColor.App.label
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(name: String, iconName: String) {
        nameLabel.text = name
        let config = UIImage.SymbolConfiguration(pointSize: Constants.Catalog.subcategoryIconSize, weight: .light)
        iconView.image = UIImage(systemName: iconName, withConfiguration: config)
    }

    private func setupUI() {
        contentView.backgroundColor = UIColor.App.secondaryBackground
        contentView.layer.cornerRadius = Constants.UI.cornerRadius
        contentView.clipsToBounds = true

        let stack = UIStackView(arrangedSubviews: [iconView, nameLabel])
        stack.axis = .vertical
        stack.spacing = Constants.UI.smallPadding / 2
        stack.alignment = .center

        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: Constants.UI.smallPadding / 2),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -Constants.UI.smallPadding / 2),
        ])
    }
}
