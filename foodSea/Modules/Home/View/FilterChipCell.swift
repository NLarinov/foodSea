import UIKit

final class FilterChipCell: UICollectionViewCell {
    static let reuseIdentifier = "FilterChipCell"

    private let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize, weight: .medium)
        label.textAlignment = .center
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

    func configure(title: String, isSelected: Bool) {
        label.text = title
        if isSelected {
            contentView.backgroundColor = UIColor.App.primary
            label.textColor = .white
        } else {
            contentView.backgroundColor = UIColor.App.secondaryBackground
            label.textColor = UIColor.App.label
        }
    }

    private func setupUI() {
        contentView.layer.cornerRadius = Constants.Home.filterChipHeight / 2
        contentView.clipsToBounds = true

        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.UI.standardPadding),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.UI.standardPadding),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
}
