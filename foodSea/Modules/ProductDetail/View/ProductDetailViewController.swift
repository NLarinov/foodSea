import UIKit
import Combine

final class ProductDetailViewController: UIViewController {
    var onSimilarProductSelected: ((Product) -> Void)?

    private let viewModel: ProductDetailViewModel
    private var cancellables = Set<AnyCancellable>()
    private var priceEntries: [PriceEntry] = []

    private let scrollView = UIScrollView()
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Constants.UI.standardPadding
        return stack
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let productImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = UIColor.App.secondaryBackground
        iv.layer.cornerRadius = Constants.UI.cornerRadius
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor.App.secondary
        iv.image = UIImage(systemName: "photo.fill")
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.largeTitleFontSize, weight: .bold)
        label.textColor = UIColor.App.label
        label.numberOfLines = 0
        return label
    }()

    private let brandLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize)
        label.textColor = UIColor.App.secondaryLabel
        return label
    }()

    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize)
        label.textColor = UIColor.App.secondaryLabel
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize)
        label.textColor = UIColor.App.label
        label.numberOfLines = 0
        return label
    }()

    private let barcodeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.captionFontSize)
        label.textColor = UIColor.App.secondaryLabel
        return label
    }()

    private let pricesSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Цены в магазинах"
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .semibold)
        label.textColor = UIColor.App.label
        return label
    }()

    private let priceTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.isScrollEnabled = true
        table.alwaysBounceVertical = true
        table.separatorInset = UIEdgeInsets(
            top: 0,
            left: Constants.UI.separatorInset,
            bottom: 0,
            right: Constants.UI.separatorInset
        )
        table.register(PriceComparisonCell.self, forCellReuseIdentifier: PriceComparisonCell.reuseIdentifier)
        return table
    }()

    private var priceTableHeightConstraint: NSLayoutConstraint?

    private let similarSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Похожие товары"
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .semibold)
        label.textColor = UIColor.App.label
        return label
    }()

    private lazy var similarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: SimilarProductCell.cellWidth, height: SimilarProductCell.cellWidth + Constants.UI.thumbnailSize / 2)
        layout.minimumInteritemSpacing = Constants.UI.cellSpacing
        layout.sectionInset = UIEdgeInsets(
            top: 0,
            left: Constants.UI.standardPadding,
            bottom: 0,
            right: Constants.UI.standardPadding
        )
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.showsHorizontalScrollIndicator = false
        collection.backgroundColor = .clear
        collection.register(SimilarProductCell.self, forCellWithReuseIdentifier: SimilarProductCell.reuseIdentifier)
        return collection
    }()

    private let quantityContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Constants.UI.standardPadding
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()

    private let decrementButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "minus")
        config.baseBackgroundColor = UIColor.App.secondaryBackground
        config.baseForegroundColor = UIColor.App.label
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private let quantityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .semibold)
        label.textColor = UIColor.App.label
        label.textAlignment = .center
        label.text = "1"
        return label
    }()

    private let incrementButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "plus")
        config.baseBackgroundColor = UIColor.App.secondaryBackground
        config.baseForegroundColor = UIColor.App.label
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private let addToCartButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = Constants.Strings.addToCartButton
        config.baseBackgroundColor = UIColor.App.primary
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    nonisolated init(viewModel: ProductDetailViewModel) {
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
        setupActions()
        bindViewModel()
        viewModel.loadProduct()
        viewModel.loadSimilarProducts()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let navBarHeight = navigationController?.navigationBar.frame.height ?? 0
        let inset = UIEdgeInsets(top: -navBarHeight, left: 0, bottom: 0, right: 0)
        if additionalSafeAreaInsets != inset {
            additionalSafeAreaInsets = inset
        }
    }

    private func setupUI() {
        view.backgroundColor = UIColor.App.background

        view.addSubview(scrollView)
        scrollView.pinToSuperviewSafeArea()

        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        productImageView.translatesAutoresizingMaskIntoConstraints = false
        productImageView.heightAnchor.constraint(
            equalTo: productImageView.widthAnchor,
            multiplier: Constants.UI.productImageAspectRatio
        ).isActive = true

        let infoStack = UIStackView(arrangedSubviews: [nameLabel, brandLabel, categoryLabel, descriptionLabel, barcodeLabel])
        infoStack.axis = .vertical
        infoStack.spacing = Constants.UI.smallPadding
        infoStack.layoutMargins = UIEdgeInsets(
            top: 0,
            left: Constants.UI.standardPadding,
            bottom: 0,
            right: Constants.UI.standardPadding
        )
        infoStack.isLayoutMarginsRelativeArrangement = true

        let priceSection = UIStackView(arrangedSubviews: [pricesSectionLabel, priceTableView])
        priceSection.axis = .vertical
        priceSection.spacing = Constants.UI.smallPadding
        priceSection.layoutMargins = UIEdgeInsets(
            top: 0,
            left: Constants.UI.standardPadding,
            bottom: 0,
            right: Constants.UI.standardPadding
        )
        priceSection.isLayoutMarginsRelativeArrangement = true

        let tableHeight = priceTableView.heightAnchor.constraint(equalToConstant: 0)
        tableHeight.priority = .defaultHigh
        tableHeight.isActive = true
        priceTableHeightConstraint = tableHeight

        priceTableView.dataSource = self
        priceTableView.delegate = self

        let similarSection = UIStackView(arrangedSubviews: [similarSectionLabel, similarCollectionView])
        similarSection.axis = .vertical
        similarSection.spacing = Constants.UI.smallPadding

        similarSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        let labelWrapper = UIView()
        labelWrapper.addSubview(similarSectionLabel)
        similarSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            similarSectionLabel.topAnchor.constraint(equalTo: labelWrapper.topAnchor),
            similarSectionLabel.leadingAnchor.constraint(equalTo: labelWrapper.leadingAnchor, constant: Constants.UI.standardPadding),
            similarSectionLabel.trailingAnchor.constraint(equalTo: labelWrapper.trailingAnchor, constant: -Constants.UI.standardPadding),
            similarSectionLabel.bottomAnchor.constraint(equalTo: labelWrapper.bottomAnchor),
        ])

        let similarStack = UIStackView(arrangedSubviews: [labelWrapper, similarCollectionView])
        similarStack.axis = .vertical
        similarStack.spacing = Constants.UI.smallPadding

        similarCollectionView.translatesAutoresizingMaskIntoConstraints = false
        similarCollectionView.heightAnchor.constraint(
            equalToConstant: SimilarProductCell.cellWidth + Constants.UI.thumbnailSize / 2
        ).isActive = true
        similarCollectionView.dataSource = self
        similarCollectionView.delegate = self

        decrementButton.setSize(width: Constants.UI.minimumTapSize, height: Constants.UI.minimumTapSize)
        incrementButton.setSize(width: Constants.UI.minimumTapSize, height: Constants.UI.minimumTapSize)
        quantityLabel.setSize(width: Constants.UI.minimumTapSize)

        let quantityTitleLabel = UILabel()
        quantityTitleLabel.text = "Количество"
        quantityTitleLabel.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .medium)
        quantityTitleLabel.textColor = UIColor.App.label

        let stepperStack = UIStackView(arrangedSubviews: [decrementButton, quantityLabel, incrementButton])
        stepperStack.axis = .horizontal
        stepperStack.spacing = Constants.UI.smallPadding
        stepperStack.alignment = .center

        quantityContainer.addArrangedSubview(quantityTitleLabel)
        quantityContainer.addArrangedSubview(UIView())
        quantityContainer.addArrangedSubview(stepperStack)
        quantityContainer.layoutMargins = UIEdgeInsets(
            top: 0,
            left: Constants.UI.standardPadding,
            bottom: 0,
            right: Constants.UI.standardPadding
        )
        quantityContainer.isLayoutMarginsRelativeArrangement = true

        addToCartButton.translatesAutoresizingMaskIntoConstraints = false
        addToCartButton.heightAnchor.constraint(equalToConstant: Constants.UI.buttonHeight).isActive = true

        let buttonWrapper = UIView()
        buttonWrapper.addSubview(addToCartButton)
        addToCartButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addToCartButton.topAnchor.constraint(equalTo: buttonWrapper.topAnchor),
            addToCartButton.leadingAnchor.constraint(equalTo: buttonWrapper.leadingAnchor, constant: Constants.UI.standardPadding),
            addToCartButton.trailingAnchor.constraint(equalTo: buttonWrapper.trailingAnchor, constant: -Constants.UI.standardPadding),
            addToCartButton.bottomAnchor.constraint(equalTo: buttonWrapper.bottomAnchor),
        ])

        contentStack.addArrangedSubview(productImageView)
        contentStack.addArrangedSubview(infoStack)
        contentStack.addArrangedSubview(priceSection)
        contentStack.addArrangedSubview(quantityContainer)
        contentStack.addArrangedSubview(buttonWrapper)
        contentStack.addArrangedSubview(similarStack)

        let bottomSpacer = UIView()
        bottomSpacer.setSize(height: Constants.UI.largePadding)
        contentStack.addArrangedSubview(bottomSpacer)

        view.addSubview(activityIndicator)
        activityIndicator.centerInSuperview()

        contentStack.isHidden = true
    }

    private func setupActions() {
        decrementButton.addTarget(self, action: #selector(decrementTapped), for: .touchUpInside)
        incrementButton.addTarget(self, action: #selector(incrementTapped), for: .touchUpInside)
        addToCartButton.addTarget(self, action: #selector(addToCartTapped), for: .touchUpInside)
    }

    @objc private func decrementTapped() {
        viewModel.decrementQuantity()
    }

    @objc private func incrementTapped() {
        viewModel.incrementQuantity()
    }

    @objc private func addToCartTapped() {
        viewModel.addToCart()
    }

    private func bindViewModel() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading {
                    self?.activityIndicator.startAnimating()
                    self?.contentStack.isHidden = true
                } else {
                    self?.activityIndicator.stopAnimating()
                    self?.contentStack.isHidden = false
                }
            }
            .store(in: &cancellables)

        viewModel.$product
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] product in
                self?.updateUI(with: product)
            }
            .store(in: &cancellables)

        viewModel.$quantity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] quantity in
                self?.quantityLabel.text = "\(quantity)"
                self?.decrementButton.isEnabled = quantity > Constants.Cart.minQuantity
                self?.incrementButton.isEnabled = quantity < Constants.Cart.maxQuantity
            }
            .store(in: &cancellables)

        viewModel.$addedToCart
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { [weak self] _ in
                self?.showToast(Constants.Strings.addedToCart)
            }
            .store(in: &cancellables)

        viewModel.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)

        viewModel.$similarProducts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.similarCollectionView.reloadData()
            }
            .store(in: &cancellables)
    }

    private func updateUI(with product: Product) {
        navigationItem.title = nil
        nameLabel.text = product.name
        brandLabel.text = product.brand
        categoryLabel.text = product.category.name
        descriptionLabel.text = product.description
        barcodeLabel.text = product.barcode
        productImageView.setRemoteImage(product.imageURL, placeholderSymbol: "photo.fill")

        addToCartButton.isEnabled = product.isAvailable
        addToCartButton.alpha = product.isAvailable ? 1 : 0.5

        priceEntries = product.prices.sorted { $0.price < $1.price }
        priceTableView.reloadData()
        updateTableHeight()
    }

    private func updateTableHeight() {
        priceTableView.layoutIfNeeded()
        let content = priceTableView.contentSize.height
        let capped = min(content, Constants.UI.priceTableMaxHeight)
        priceTableHeightConstraint?.constant = capped
    }
}

extension ProductDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        priceEntries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PriceComparisonCell.reuseIdentifier,
            for: indexPath
        ) as? PriceComparisonCell else {
            return UITableViewCell()
        }
        let entry = priceEntries[indexPath.row]
        cell.configure(with: entry, isCheapest: indexPath.row == 0)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}

extension ProductDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.similarProducts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SimilarProductCell.reuseIdentifier,
            for: indexPath
        ) as? SimilarProductCell else {
            return UICollectionViewCell()
        }
        let product = viewModel.similarProducts[indexPath.item]
        cell.configure(with: product)
        cell.onTap = { [weak self] in
            self?.onSimilarProductSelected?(product)
        }
        return cell
    }
}
