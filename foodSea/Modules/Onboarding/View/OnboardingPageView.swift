import UIKit

final class OnboardingPageView: UIView {

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .App.primary
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: Constants.UI.largeTitleFontSize, weight: .bold)
        label.textColor = .App.label
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .regular)
        label.textColor = .App.secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    init(title: String, description: String, iconName: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        descriptionLabel.text = description
        iconImageView.image = UIImage(
            systemName: iconName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 80, weight: .medium)
        )
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupLayout() {
        let stackView = UIStackView(arrangedSubviews: [iconImageView, titleLabel, descriptionLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Constants.UI.largePadding

        addSubview(stackView)

        NSLayoutConstraint.activate([
            iconImageView.heightAnchor.constraint(equalToConstant: 120),
            iconImageView.widthAnchor.constraint(equalToConstant: 120),

            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.UI.largePadding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.UI.largePadding),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -Constants.UI.largePadding)
        ])
    }
}
