import UIKit
import Combine

final class CartViewController: UIViewController {
    var onProductSelected: ((Product) -> Void)?
    var onGoToCatalog: (() -> Void)?
    var onOptimize: (() -> Void)?
    var onVoiceInput: (() -> Void)?

    private let viewModel: CartViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = UIColor.App.background
        tv.delegate = self
        tv.dataSource = self
        tv.register(CartItemCell.self, forCellReuseIdentifier: CartItemCell.reuseIdentifier)
        tv.separatorInset = UIEdgeInsets(
            top: 0,
            left: Constants.UI.separatorInset,
            bottom: 0,
            right: Constants.UI.separatorInset
        )
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = Constants.UI.thumbnailSize + Constants.UI.standardPadding * 2
        return tv
    }()

    private let bottomBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.App.secondaryBackground
        return view
    }()

    private let totalLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .bold)
        label.textColor = UIColor.App.label
        return label
    }()

    private let optimizeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = Constants.Strings.optimizeButton
        config.baseBackgroundColor = UIColor.App.primary
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private let emptyScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isHidden = true
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let emptyContentView = UIView()

    private let emptyImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .light)
        iv.image = UIImage(systemName: "cart", withConfiguration: config)
        iv.tintColor = UIColor.App.secondary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Strings.emptyCartMessage
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .semibold)
        label.textColor = UIColor.App.label
        label.textAlignment = .center
        return label
    }()

    private let emptySubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Strings.emptyCartSubtitle
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize)
        label.textColor = UIColor.App.secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let goToCatalogButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = Constants.Strings.emptyCartAction
        config.baseBackgroundColor = UIColor.App.primary
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "square.grid.2x2.fill")
        config.imagePadding = Constants.UI.smallPadding
        let button = UIButton(configuration: config)
        return button
    }()

    private let recommendedHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Strings.recommendedProducts
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .bold)
        label.textColor = UIColor.App.label
        return label
    }()

    private let recommendedStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = Constants.UI.cellSpacing
        return sv
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    init(viewModel: CartViewModel) {
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadCart()
        viewModel.loadRecommendedProducts()
    }

    private func setupUI() {
        title = Constants.TabBar.cartTitle
        view.backgroundColor = UIColor.App.background
        navigationItem.largeTitleDisplayMode = .always

        let voiceButton = UIBarButtonItem(
            image: UIImage(systemName: "mic.fill"),
            style: .plain,
            target: self,
            action: #selector(voiceInputTapped)
        )
        let clearButton = UIBarButtonItem(
            title: Constants.Strings.clearCart,
            style: .plain,
            target: self,
            action: #selector(clearCartTapped)
        )
        clearButton.tintColor = UIColor.App.error
        navigationItem.rightBarButtonItems = [clearButton, voiceButton]

        let bottomStack = UIStackView(arrangedSubviews: [totalLabel, optimizeButton])
        bottomStack.axis = .horizontal
        bottomStack.spacing = Constants.UI.standardPadding
        bottomStack.alignment = .center

        optimizeButton.setSize(height: Constants.UI.buttonHeight)
        optimizeButton.setContentHuggingPriority(.required, for: .horizontal)

        bottomBar.addSubview(bottomStack)
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomStack.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: Constants.UI.standardPadding),
            bottomStack.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: Constants.UI.standardPadding),
            bottomStack.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -Constants.UI.standardPadding),
            bottomStack.bottomAnchor.constraint(equalTo: bottomBar.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.UI.smallPadding),
        ])

        setupEmptyState()

        view.addSubview(tableView)
        view.addSubview(bottomBar)
        view.addSubview(emptyScrollView)
        view.addSubview(activityIndicator)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        emptyScrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        activityIndicator.centerInSuperview()

        optimizeButton.addTarget(self, action: #selector(optimizeTapped), for: .touchUpInside)
        goToCatalogButton.addTarget(self, action: #selector(goToCatalogTapped), for: .touchUpInside)
    }

    private func setupEmptyState() {
        let emptyHeaderStack = UIStackView(arrangedSubviews: [emptyImageView, emptyLabel, emptySubtitleLabel, goToCatalogButton])
        emptyHeaderStack.axis = .vertical
        emptyHeaderStack.spacing = Constants.UI.smallPadding
        emptyHeaderStack.alignment = .center
        emptyHeaderStack.setCustomSpacing(Constants.UI.standardPadding, after: emptySubtitleLabel)
        goToCatalogButton.setSize(height: Constants.UI.buttonHeight)

        emptyScrollView.addSubview(emptyContentView)
        emptyContentView.translatesAutoresizingMaskIntoConstraints = false

        emptyContentView.addSubview(emptyHeaderStack)
        emptyContentView.addSubview(recommendedHeaderLabel)
        emptyContentView.addSubview(recommendedStackView)

        emptyHeaderStack.translatesAutoresizingMaskIntoConstraints = false
        recommendedHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        recommendedStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            emptyContentView.topAnchor.constraint(equalTo: emptyScrollView.topAnchor),
            emptyContentView.leadingAnchor.constraint(equalTo: emptyScrollView.leadingAnchor),
            emptyContentView.trailingAnchor.constraint(equalTo: emptyScrollView.trailingAnchor),
            emptyContentView.bottomAnchor.constraint(equalTo: emptyScrollView.bottomAnchor),
            emptyContentView.widthAnchor.constraint(equalTo: emptyScrollView.widthAnchor),

            emptyHeaderStack.topAnchor.constraint(equalTo: emptyContentView.topAnchor, constant: Constants.UI.largePadding),
            emptyHeaderStack.leadingAnchor.constraint(equalTo: emptyContentView.leadingAnchor, constant: Constants.UI.largePadding),
            emptyHeaderStack.trailingAnchor.constraint(equalTo: emptyContentView.trailingAnchor, constant: -Constants.UI.largePadding),

            recommendedHeaderLabel.topAnchor.constraint(equalTo: emptyHeaderStack.bottomAnchor, constant: Constants.UI.largePadding),
            recommendedHeaderLabel.leadingAnchor.constraint(equalTo: emptyContentView.leadingAnchor, constant: Constants.UI.standardPadding),
            recommendedHeaderLabel.trailingAnchor.constraint(equalTo: emptyContentView.trailingAnchor, constant: -Constants.UI.standardPadding),

            recommendedStackView.topAnchor.constraint(equalTo: recommendedHeaderLabel.bottomAnchor, constant: Constants.UI.smallPadding),
            recommendedStackView.leadingAnchor.constraint(equalTo: emptyContentView.leadingAnchor, constant: Constants.UI.standardPadding),
            recommendedStackView.trailingAnchor.constraint(equalTo: emptyContentView.trailingAnchor, constant: -Constants.UI.standardPadding),
            recommendedStackView.bottomAnchor.constraint(equalTo: emptyContentView.bottomAnchor, constant: -Constants.UI.largePadding),
        ])
    }

    private func buildRecommendedGrid(products: [Product]) {
        recommendedStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let pairs = stride(from: 0, to: products.count, by: 2).map { i in
            let end = min(i + 2, products.count)
            return Array(products[i..<end])
        }

        for pair in pairs {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = Constants.UI.cellSpacing
            rowStack.distribution = .fillEqually

            for product in pair {
                let card = makeProductCard(product: product)
                rowStack.addArrangedSubview(card)
            }

            if pair.count == 1 {
                let spacer = UIView()
                rowStack.addArrangedSubview(spacer)
            }

            recommendedStackView.addArrangedSubview(rowStack)
        }
    }

    private func makeProductCard(product: Product) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.App.secondaryBackground
        card.layer.cornerRadius = Constants.UI.cornerRadius
        card.clipsToBounds = true

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = UIColor.App.secondary

        let nameLabel = UILabel()
        nameLabel.text = product.name
        nameLabel.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .medium)
        nameLabel.textColor = UIColor.App.label
        nameLabel.numberOfLines = 2

        let priceLabel = UILabel()
        priceLabel.font = .systemFont(ofSize: Constants.UI.priceFontSize, weight: .bold)
        priceLabel.textColor = UIColor.App.pricePrimary
        if let lowest = product.lowestPrice {
            let formatted = priceFormatter.string(from: NSDecimalNumber(decimal: lowest)) ?? "\(lowest)"
            priceLabel.text = "\(formatted) ₽"
        }

        let addButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: Constants.UI.tabBarIconSize, weight: .medium)
        addButton.setImage(UIImage(systemName: "cart.badge.plus", withConfiguration: config), for: .normal)
        addButton.tintColor = UIColor.App.primary

        let action = UIAction { [weak self] _ in
            self?.viewModel.addToCart(product: product)
        }
        addButton.addAction(action, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [imageView, nameLabel, priceLabel])
        stack.axis = .vertical
        stack.spacing = Constants.UI.smallPadding

        card.addSubview(stack)
        card.addSubview(addButton)

        stack.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: Constants.UI.thumbnailSize),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: Constants.UI.smallPadding),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Constants.UI.smallPadding),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -Constants.UI.smallPadding),

            addButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -Constants.UI.smallPadding),
            addButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -Constants.UI.smallPadding),
            addButton.widthAnchor.constraint(greaterThanOrEqualToConstant: Constants.UI.minimumTapSize),
            addButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.UI.minimumTapSize),

            stack.bottomAnchor.constraint(lessThanOrEqualTo: addButton.topAnchor, constant: -Constants.UI.smallPadding),
        ])

        let tap = CardTapGesture(target: self, action: #selector(recommendedCardTapped(_:)))
        tap.product = product
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true

        return card
    }

    @objc private func recommendedCardTapped(_ gesture: CardTapGesture) {
        guard let product = gesture.product else { return }
        onProductSelected?(product)
    }

    private func bindViewModel() {
        viewModel.$cartItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
                self?.updateBadge()
            }
            .store(in: &cancellables)

        viewModel.$isEmpty
            .receive(on: DispatchQueue.main)
            .sink { [weak self] empty in
                self?.emptyScrollView.isHidden = !empty
                self?.tableView.isHidden = empty
                self?.bottomBar.isHidden = empty
                self?.navigationItem.rightBarButtonItem?.isHidden = empty
                self?.optimizeButton.isEnabled = !empty
            }
            .store(in: &cancellables)

        viewModel.$totalCost
            .receive(on: DispatchQueue.main)
            .sink { [weak self] total in
                guard let self else { return }
                let formatted = priceFormatter.string(from: NSDecimalNumber(decimal: total)) ?? "\(total)"
                totalLabel.text = "Итого: \(formatted) ₽"
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.$recommendedProducts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] products in
                self?.buildRecommendedGrid(products: products)
            }
            .store(in: &cancellables)

        viewModel.$addedToCartMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showToast(message)
            }
            .store(in: &cancellables)
    }

    private func updateBadge() {
        let count = viewModel.cartItems.reduce(0) { $0 + $1.quantity }
        navigationController?.tabBarItem.badgeValue = count > 0 ? "\(count)" : nil
    }

    @objc private func clearCartTapped() {
        showConfirmation(
            title: Constants.Strings.clearCart,
            message: Constants.Strings.clearCartConfirmation,
            confirmTitle: Constants.Strings.clearCart
        ) { [weak self] in
            self?.viewModel.clearCart()
        }
    }

    @objc private func optimizeTapped() {
        onOptimize?()
    }

    @objc private func voiceInputTapped() {
        onVoiceInput?()
    }

    @objc private func goToCatalogTapped() {
        onGoToCatalog?()
    }
}

extension CartViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.cartItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CartItemCell.reuseIdentifier,
            for: indexPath
        ) as? CartItemCell else {
            return UITableViewCell()
        }

        let item = viewModel.cartItems[indexPath.row]
        cell.configure(with: item)
        cell.onQuantityChanged = { [weak self] newQuantity in
            self?.viewModel.updateQuantity(itemId: item.id, quantity: newQuantity)
        }
        cell.onDelete = { [weak self] in
            self?.showConfirmation(
                title: Constants.Strings.deleteConfirmation,
                message: nil,
                confirmTitle: Constants.Strings.delete
            ) {
                self?.viewModel.removeItem(itemId: item.id)
            }
        }
        return cell
    }
}

extension CartViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewModel.cartItems[indexPath.row]
        onProductSelected?(item.product)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let item = viewModel.cartItems[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: Constants.Strings.delete) { [weak self] _, _, completion in
            self?.showConfirmation(
                title: Constants.Strings.deleteConfirmation,
                message: nil,
                confirmTitle: Constants.Strings.delete
            ) {
                self?.viewModel.removeItem(itemId: item.id)
            }
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

private final class CardTapGesture: UITapGestureRecognizer {
    var product: Product?
}
