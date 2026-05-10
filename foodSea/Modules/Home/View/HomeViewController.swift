import UIKit
import Combine

final class HomeViewController: UIViewController {
    var onProductSelected: ((Product) -> Void)?
    var onSearchTapped: (() -> Void)?
    var onScannerTapped: (() -> Void)?
    var onVoiceTapped: (() -> Void)?
    var onPhotoSearchTapped: (() -> Void)?

    private let viewModel: HomeViewModel
    private var cancellables = Set<AnyCancellable>()

    nonisolated private enum SectionKind: Int, Hashable, Sendable {
        case banners
        case filters
        case products
    }

    nonisolated private struct Item: Hashable, Sendable {
        let id: String
        let kind: ItemKind
    }

    nonisolated private enum ItemKind: Hashable, Sendable {
        case banner(index: Int)
        case filter(categoryId: String?, title: String)
        case product(Product)
    }

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = UIColor.App.background
        cv.delegate = self
        cv.register(BannerCell.self, forCellWithReuseIdentifier: BannerCell.reuseIdentifier)
        cv.register(FilterChipCell.self, forCellWithReuseIdentifier: FilterChipCell.reuseIdentifier)
        cv.register(ProductCell.self, forCellWithReuseIdentifier: ProductCell.reuseIdentifier)
        cv.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier
        )
        return cv
    }()

    private lazy var dataSource: UICollectionViewDiffableDataSource<SectionKind, Item> = {
        let ds = UICollectionViewDiffableDataSource<SectionKind, Item>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            self?.configureCell(collectionView: collectionView, indexPath: indexPath, item: item)
        }

        ds.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader,
                  let header = collectionView.dequeueReusableSupplementaryView(
                      ofKind: kind,
                      withReuseIdentifier: SectionHeaderView.reuseIdentifier,
                      for: indexPath
                  ) as? SectionHeaderView else {
                return UICollectionReusableView()
            }
            let section = SectionKind(rawValue: indexPath.section)
            switch section {
            case .banners:
                header.configure(title: Constants.Home.promoTitle)
            case .products:
                header.configure(title: Constants.Home.forYouTitle)
            default:
                break
            }
            return header
        }

        return ds
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return rc
    }()

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.loadProducts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshCartQuantities()
    }

    private func setupUI() {
        title = Constants.TabBar.homeTitle
        view.backgroundColor = UIColor.App.background
        navigationItem.largeTitleDisplayMode = .always

        let scannerButton = UIBarButtonItem(
            image: UIImage(systemName: "barcode.viewfinder"),
            style: .plain,
            target: self,
            action: #selector(scannerTapped)
        )
        let voiceButton = UIBarButtonItem(
            image: UIImage(systemName: "mic.fill"),
            style: .plain,
            target: self,
            action: #selector(voiceTapped)
        )
        let photoButton = UIBarButtonItem(
            image: UIImage(systemName: "camera.fill"),
            style: .plain,
            target: self,
            action: #selector(photoSearchTapped)
        )
        navigationItem.rightBarButtonItems = [scannerButton, voiceButton, photoButton]

        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = Constants.Strings.emptySearchMessage
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true

        view.addSubview(collectionView)
        collectionView.pinToSuperview()
        collectionView.refreshControl = refreshControl

        view.addSubview(activityIndicator)
        activityIndicator.centerInSuperview()
    }

    private func configureCell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        item: Item
    ) -> UICollectionViewCell {
        switch item.kind {
        case .banner(let index):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: BannerCell.reuseIdentifier,
                for: indexPath
            ) as? BannerCell else {
                return UICollectionViewCell()
            }
            let banner = viewModel.banners[index]
            cell.configure(title: banner.title, subtitle: banner.subtitle, colorName: banner.color)
            return cell

        case .filter(let categoryId, let title):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FilterChipCell.reuseIdentifier,
                for: indexPath
            ) as? FilterChipCell else {
                return UICollectionViewCell()
            }
            cell.configure(title: title, isSelected: viewModel.selectedCategory == categoryId)
            return cell

        case .product(let product):
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ProductCell.reuseIdentifier,
                for: indexPath
            ) as? ProductCell else {
                return UICollectionViewCell()
            }
            let qty = viewModel.quantity(for: product.id)
            cell.configure(with: product, quantity: qty)
            cell.addToCartAction = { [weak self] in
                self?.viewModel.addToCart(product: product)
            }
            cell.onQuantityChanged = { [weak self] newQty in
                self?.viewModel.updateCartQuantity(productId: product.id, quantity: newQty)
            }
            return cell
        }
    }

    private func bindViewModel() {
        viewModel.$products
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applySnapshot()
            }
            .store(in: &cancellables)

        viewModel.$categories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applySnapshot()
            }
            .store(in: &cancellables)

        viewModel.$banners
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applySnapshot()
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                guard let self else { return }
                if loading && viewModel.products.isEmpty {
                    activityIndicator.startAnimating()
                } else {
                    activityIndicator.stopAnimating()
                    refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)

        viewModel.$cartQuantities
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let snapshot = dataSource.snapshot()
                dataSource.applySnapshotUsingReloadData(snapshot)
            }
            .store(in: &cancellables)
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<SectionKind, Item>()

        snapshot.appendSections([SectionKind.banners])
        let bannerItems = viewModel.banners.enumerated().map {
            Item(id: "banner_\($0.offset)", kind: .banner(index: $0.offset))
        }
        snapshot.appendItems(bannerItems, toSection: SectionKind.banners)

        snapshot.appendSections([SectionKind.filters])
        var filterItems = [Item(id: "filter_all", kind: .filter(categoryId: nil, title: Constants.Home.allFilterTitle))]
        filterItems += viewModel.categories.map {
            Item(id: "filter_\($0.id)", kind: .filter(categoryId: $0.id, title: $0.name))
        }
        snapshot.appendItems(filterItems, toSection: SectionKind.filters)

        snapshot.appendSections([SectionKind.products])
        let productItems = viewModel.products.map {
            Item(id: "product_\($0.id)", kind: .product($0))
        }
        snapshot.appendItems(productItems, toSection: SectionKind.products)

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let section = SectionKind(rawValue: sectionIndex) else { return nil }
            switch section {
            case .banners:
                return self?.makeBannerSection()
            case .filters:
                return self?.makeFilterSection()
            case .products:
                return self?.makeProductSection()
            }
        }
    }

    private func makeBannerSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.85),
            heightDimension: .absolute(Constants.Home.bannerHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.interGroupSpacing = Constants.UI.cellSpacing
        section.contentInsets = NSDirectionalEdgeInsets(
            top: Constants.UI.standardPadding,
            leading: Constants.UI.standardPadding,
            bottom: Constants.UI.smallPadding,
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

    private func makeFilterSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(80),
            heightDimension: .absolute(Constants.Home.filterChipHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(80),
            heightDimension: .absolute(Constants.Home.filterChipHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = Constants.UI.smallPadding
        section.contentInsets = NSDirectionalEdgeInsets(
            top: Constants.UI.smallPadding,
            leading: Constants.UI.standardPadding,
            bottom: Constants.UI.smallPadding,
            trailing: Constants.UI.standardPadding
        )
        return section
    }

    private func makeProductSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .estimated(Constants.UI.productImageHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(Constants.UI.productImageHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            repeatingSubitem: item,
            count: 2
        )
        group.interItemSpacing = .fixed(Constants.UI.cellSpacing)

        let section = NSCollectionLayoutSection(group: group)
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

    @objc private func handleRefresh() {
        viewModel.loadProducts()
    }

    @objc private func scannerTapped() {
        onScannerTapped?()
    }

    @objc private func voiceTapped() {
        onVoiceTapped?()
    }

    @objc private func photoSearchTapped() {
        onPhotoSearchTapped?()
    }
}

extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item.kind {
        case .banner(let index):
            guard viewModel.banners.indices.contains(index) else { return }
            onProductSelected?(viewModel.banners[index].product)
        case .filter(let categoryId, _):
            viewModel.selectCategory(categoryId)
        case .product(let product):
            onProductSelected?(product)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard SectionKind(rawValue: indexPath.section) == .products else { return }
        let snapshot = dataSource.snapshot()
        let itemCount = snapshot.numberOfItems(inSection: .products)
        if indexPath.item >= itemCount - Constants.API.itemsPerPage / 2 {
            viewModel.loadNextPage()
        }
    }
}

extension HomeViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        navigationItem.searchController?.isActive = false
        onSearchTapped?()
        return false
    }
}

final class SectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "SectionHeaderView"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .bold)
        label.textColor = UIColor.App.label
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Constants.UI.smallPadding),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.UI.smallPadding),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(title: String) {
        titleLabel.text = title
    }
}
