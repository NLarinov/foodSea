import UIKit

final class BannerCell: UICollectionViewCell {
    static let reuseIdentifier = "BannerCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.largeTitleFontSize, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize)
        label.textColor = UIColor.white.withAlphaComponent(0.9)
        label.numberOfLines = 2
        return label
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
        iv.image = UIImage(systemName: "tag.fill", withConfiguration: config)
        iv.tintColor = UIColor.white.withAlphaComponent(0.3)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(title: String, subtitle: String, colorName: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle

        let color: UIColor
        switch colorName {
        case "systemOrange": color = .systemOrange
        case "systemBlue": color = .systemBlue
        case "systemPurple": color = .systemPurple
        case "systemRed": color = .systemRed
        case "systemGreen": color = .systemGreen
        default: color = UIColor.App.primary
        }
        contentView.backgroundColor = color
    }

    private func setupUI() {
        contentView.layer.cornerRadius = Constants.UI.cornerRadius
        contentView.clipsToBounds = true

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = Constants.UI.smallPadding / 2

        contentView.addSubview(textStack)
        contentView.addSubview(iconView)

        textStack.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.UI.standardPadding),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: iconView.leadingAnchor, constant: -Constants.UI.standardPadding),

            iconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.UI.standardPadding),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 60),
            iconView.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
}
