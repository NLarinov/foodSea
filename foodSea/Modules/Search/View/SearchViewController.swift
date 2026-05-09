import UIKit
import Combine

final class SearchViewController: UIViewController {
    nonisolated enum Section: Sendable { case main }

    var onProductSelected: ((Product) -> Void)?

    private let viewModel: SearchViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = Constants.Strings.emptySearchMessage
        sb.delegate = self
        sb.showsCancelButton = true
        return sb
    }()

    private let filterButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: Constants.UI.titleFontSize, weight: .medium)
        button.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle", withConfiguration: config), for: .normal)
        button.tintColor = UIColor.App.primary
        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        cv.backgroundColor = UIColor.App.background
        cv.delegate = self
        cv.register(ProductCell.self, forCellWithReuseIdentifier: ProductCell.reuseIdentifier)
        cv.keyboardDismissMode = .onDrag
        return cv
    }()

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Product> = {
        UICollectionViewDiffableDataSource<Section, Product>(
            collectionView: collectionView
        ) { collectionView, indexPath, product in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ProductCell.reuseIdentifier,
                for: indexPath
            ) as? ProductCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: product)
            return cell
        }
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let categoryService: any CategoryServiceProtocol

    init(viewModel: SearchViewModel, categoryService: any CategoryServiceProtocol) {
        self.viewModel = viewModel
        self.categoryService = categoryService
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
        searchBar.becomeFirstResponder()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.App.background
        navigationItem.largeTitleDisplayMode = .never

        let searchContainer = UIStackView(arrangedSubviews: [filterButton, searchBar])
        searchContainer.axis = .horizontal
        searchContainer.spacing = Constants.UI.smallPadding
        searchContainer.alignment = .center
        filterButton.setSize(width: Constants.UI.minimumTapSize, height: Constants.UI.minimumTapSize)

        view.addSubview(searchContainer)
        view.addSubview(collectionView)
        view.addSubview(activityIndicator)

        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.UI.smallPadding),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        activityIndicator.centerInSuperview()

        filterButton.addTarget(self, action: #selector(filterTapped), for: .touchUpInside)
    }

    private func bindViewModel() {
        viewModel.$searchResults
            .receive(on: DispatchQueue.main)
            .sink { [weak self] products in
                self?.applySnapshot(products: products)
            }
            .store(in: &cancellables)

        viewModel.$isSearching
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searching in
                if searching {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
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

        viewModel.$filters
            .receive(on: DispatchQueue.main)
            .sink { [weak self] filters in
                let hasFilters = filters != nil && !(filters?.isEmpty ?? true)
                let iconName = hasFilters
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle"
                let config = UIImage.SymbolConfiguration(pointSize: Constants.UI.titleFontSize, weight: .medium)
                self?.filterButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
            }
            .store(in: &cancellables)
    }

    private func applySnapshot(products: [Product]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Product>()
        snapshot.appendSections([.main])
        snapshot.appendItems(products, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)

        let queryIsEmpty = viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty
        if products.isEmpty && !viewModel.isSearching && !queryIsEmpty {
            var config = UIContentUnavailableConfiguration.empty()
            config.text = Constants.Strings.emptySearchMessage
            config.secondaryText = Constants.Strings.emptySearchHint
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

    @objc private func filterTapped() {
        let filterVM = FilterViewModel(
            categoryService: categoryService,
            currentFilters: viewModel.filters
        )
        let filterVC = FilterViewController(viewModel: filterVM)
        filterVC.onApply = { [weak self] filters in
            if filters.isEmpty {
                self?.viewModel.clearFilters()
            } else {
                self?.viewModel.applyFilters(filters)
            }
        }

        if let sheet = filterVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        present(filterVC, animated: true)
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.search(query: searchText)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.clearSearch()
        navigationController?.popViewController(animated: true)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let product = dataSource.itemIdentifier(for: indexPath) else { return }
        onProductSelected?(product)
    }
}
