import UIKit
import Combine

final class CartViewController: UIViewController {
    var onProductSelected: ((Product) -> Void)?
    var onGoToCatalog: (() -> Void)?
    var onOptimize: (() -> Void)?

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

    private let emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Strings.emptyCartMessage
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .medium)
        label.textColor = UIColor.App.secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let goToCatalogButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = Constants.Strings.emptyCartAction
        config.baseBackgroundColor = UIColor.App.primary
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
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
    }

    private func setupUI() {
        title = Constants.TabBar.cartTitle
        view.backgroundColor = UIColor.App.background
        navigationItem.largeTitleDisplayMode = .always

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: Constants.Strings.clearCart,
            style: .plain,
            target: self,
            action: #selector(clearCartTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = UIColor.App.error

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

        let emptyStack = UIStackView(arrangedSubviews: [emptyLabel, goToCatalogButton])
        emptyStack.axis = .vertical
        emptyStack.spacing = Constants.UI.standardPadding
        emptyStack.alignment = .center
        goToCatalogButton.setSize(height: Constants.UI.buttonHeight)

        emptyStateView.addSubview(emptyStack)
        emptyStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStack.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStack.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
            emptyStack.leadingAnchor.constraint(greaterThanOrEqualTo: emptyStateView.leadingAnchor, constant: Constants.UI.largePadding),
            emptyStack.trailingAnchor.constraint(lessThanOrEqualTo: emptyStateView.trailingAnchor, constant: -Constants.UI.largePadding),
        ])

        view.addSubview(tableView)
        view.addSubview(bottomBar)
        view.addSubview(emptyStateView)
        view.addSubview(activityIndicator)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        activityIndicator.centerInSuperview()

        optimizeButton.addTarget(self, action: #selector(optimizeTapped), for: .touchUpInside)
        goToCatalogButton.addTarget(self, action: #selector(goToCatalogTapped), for: .touchUpInside)
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
                self?.emptyStateView.isHidden = !empty
                self?.tableView.isHidden = empty
                self?.bottomBar.isHidden = empty
                self?.navigationItem.rightBarButtonItem?.isHidden = empty
            }
            .store(in: &cancellables)

        viewModel.$totalCost
            .receive(on: DispatchQueue.main)
            .sink { [weak self] total in
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.minimumFractionDigits = 0
                formatter.maximumFractionDigits = 2
                let formatted = formatter.string(from: NSDecimalNumber(decimal: total)) ?? "\(total)"
                self?.totalLabel.text = "Итого: \(formatted) ₽"
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
            self?.viewModel.removeItem(itemId: item.id)
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
            self?.viewModel.removeItem(itemId: item.id)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
