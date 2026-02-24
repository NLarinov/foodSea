import UIKit

final class CatalogBrowseViewController: UIViewController {
    var onCategorySelected: ((String) -> Void)?

    private struct SectionData {
        let category: Category
        let subcategories: [MockData.Subcategory]
    }

    private var sections: [SectionData] = []

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = UIColor.App.background
        cv.delegate = self
        cv.dataSource = self
        cv.register(SubcategoryCell.self, forCellWithReuseIdentifier: SubcategoryCell.reuseIdentifier)
        cv.register(
            CatalogSectionHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: CatalogSectionHeader.reuseIdentifier
        )
        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupUI()
    }

    private func setupData() {
        sections = MockData.categories.compactMap { category in
            guard let subs = MockData.subcategories[category.id], !subs.isEmpty else { return nil }
            return SectionData(category: category, subcategories: subs)
        }
    }

    private func setupUI() {
        view.backgroundColor = UIColor.App.background
        navigationItem.largeTitleDisplayMode = .always

        view.addSubview(collectionView)
        collectionView.pinToSuperview()
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(Constants.Catalog.subcategoryCellWidth),
                heightDimension: .absolute(Constants.Catalog.subcategoryCellHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(Constants.Catalog.subcategoryCellWidth),
                heightDimension: .absolute(Constants.Catalog.subcategoryCellHeight)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = Constants.UI.cellSpacing
            section.contentInsets = NSDirectionalEdgeInsets(
                top: Constants.UI.smallPadding,
                leading: Constants.UI.standardPadding,
                bottom: Constants.UI.standardPadding,
                trailing: Constants.UI.standardPadding
            )

            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(Constants.UI.sectionHeaderHeight)
            )
            section.boundarySupplementaryItems = [
                NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
            ]
            return section
        }
    }
}

extension CatalogBrowseViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections[section].subcategories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SubcategoryCell.reuseIdentifier,
            for: indexPath
        ) as? SubcategoryCell else {
            return UICollectionViewCell()
        }
        let sub = sections[indexPath.section].subcategories[indexPath.item]
        cell.configure(name: sub.name, iconName: sub.iconName)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(
                  ofKind: kind,
                  withReuseIdentifier: CatalogSectionHeader.reuseIdentifier,
                  for: indexPath
              ) as? CatalogSectionHeader else {
            return UICollectionReusableView()
        }
        let section = sections[indexPath.section]
        header.configure(title: section.category.name, iconName: section.category.iconName)
        return header
    }
}

extension CatalogBrowseViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sub = sections[indexPath.section].subcategories[indexPath.item]
        onCategorySelected?(sub.categoryId)
    }
}

final class CatalogSectionHeader: UICollectionReusableView {
    static let reuseIdentifier = "CatalogSectionHeader"

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = UIColor.App.primary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .bold)
        label.textColor = UIColor.App.label
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel])
        stack.axis = .horizontal
        stack.spacing = Constants.UI.smallPadding
        stack.alignment = .center

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        iconView.setSize(width: Constants.UI.tabBarIconSize, height: Constants.UI.tabBarIconSize)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Constants.UI.standardPadding),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.UI.smallPadding / 2),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(title: String, iconName: String?) {
        titleLabel.text = title
        if let iconName {
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            iconView.image = UIImage(systemName: iconName, withConfiguration: config)
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
        }
    }
}
