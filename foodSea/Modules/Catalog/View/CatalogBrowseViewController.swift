import UIKit

final class CatalogBrowseViewController: UIViewController {
    var onSubcategorySelected: ((Category) -> Void)?

    private let categoryService: any CategoryServiceProtocol
    private var sections: [Category] = []

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
        cv.refreshControl = refreshControl
        return cv
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refreshTriggered), for: .valueChanged)
        return rc
    }()

    private lazy var spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .large)
        s.hidesWhenStopped = true
        return s
    }()

    private lazy var errorLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.textAlignment = .center
        l.textColor = UIColor.App.secondary
        l.isHidden = true
        return l
    }()

    init(categoryService: any CategoryServiceProtocol) {
        self.categoryService = categoryService
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadTree()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.App.background
        navigationItem.largeTitleDisplayMode = .always

        view.addSubview(collectionView)
        view.addSubview(spinner)
        view.addSubview(errorLabel)
        collectionView.pinToSuperview()

        spinner.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.UI.standardPadding),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.UI.standardPadding),
        ])
    }

    private func loadTree() {
        if sections.isEmpty {
            spinner.startAnimating()
        }
        errorLabel.isHidden = true
        Task { [weak self] in
            guard let self else { return }
            do {
                let tree = try await categoryService.fetchCategoryTree()
                await MainActor.run {
                    self.sections = tree.filter { !$0.children.isEmpty }
                    self.spinner.stopAnimating()
                    self.refreshControl.endRefreshing()
                    self.collectionView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.spinner.stopAnimating()
                    self.refreshControl.endRefreshing()
                    self.errorLabel.text = "Не удалось загрузить категории. Потяните вниз, чтобы повторить."
                    self.errorLabel.isHidden = false
                }
            }
        }
    }

    @objc private func refreshTriggered() {
        loadTree()
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
    func numberOfSections(in collectionView: UICollectionView) -> Int { sections.count }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections[section].children.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SubcategoryCell.reuseIdentifier,
            for: indexPath
        ) as? SubcategoryCell else {
            return UICollectionViewCell()
        }
        let sub = sections[indexPath.section].children[indexPath.item]
        cell.configure(name: sub.name, slug: sub.slug)
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
        header.configure(title: section.name, iconName: CategoryIconResolver.icon(for: section.slug))
        return header
    }
}

extension CatalogBrowseViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sub = sections[indexPath.section].children[indexPath.item]
        onSubcategorySelected?(sub)
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
