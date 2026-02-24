import UIKit
import Combine

final class CatalogViewController: UIViewController {
    nonisolated enum Section: Sendable { case main }

    var onProductSelected: ((Product) -> Void)?
    var onSearchTapped: (() -> Void)?
    var onScannerTapped: (() -> Void)?
    var onVoiceTapped: (() -> Void)?

    private let viewModel: CatalogViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = UIColor.App.background
        cv.delegate = self
        cv.register(ProductCell.self, forCellWithReuseIdentifier: ProductCell.reuseIdentifier)
        return cv
    }()

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Product> = {
        UICollectionViewDiffableDataSource<Section, Product>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, product in
            guard let self,
                  let cell = collectionView.dequeueReusableCell(
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

    init(viewModel: CatalogViewModel) {
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
        navigationItem.rightBarButtonItems = [scannerButton, voiceButton]

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

    private func bindViewModel() {
        viewModel.$products
            .receive(on: DispatchQueue.main)
            .sink { [weak self] products in
                self?.applySnapshot(products: products)
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

        viewModel.$error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.showError(error)
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

    private func applySnapshot(products: [Product]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Product>()
        snapshot.appendSections([.main])
        snapshot.appendItems(products, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)

        if products.isEmpty && !viewModel.isLoading {
            var config = UIContentUnavailableConfiguration.empty()
            config.text = Constants.Strings.emptySearchMessage
            contentUnavailableConfiguration = config
        } else {
            contentUnavailableConfiguration = nil
        }
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, _ in
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
                top: Constants.UI.standardPadding,
                leading: Constants.UI.standardPadding,
                bottom: Constants.UI.standardPadding,
                trailing: Constants.UI.standardPadding
            )
            return section
        }
    }

    @objc private func handleRefresh() {
        viewModel.refresh()
    }

    @objc private func scannerTapped() {
        onScannerTapped?()
    }

    @objc private func voiceTapped() {
        onVoiceTapped?()
    }
}

extension CatalogViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let product = dataSource.itemIdentifier(for: indexPath) else { return }
        onProductSelected?(product)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let snapshot = dataSource.snapshot()
        let itemCount = snapshot.numberOfItems(inSection: .main)
        if indexPath.item >= itemCount - Constants.API.itemsPerPage / 2 {
            viewModel.loadNextPage()
        }
    }
}

extension CatalogViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        navigationItem.searchController?.isActive = false
        onSearchTapped?()
        return false
    }
}
