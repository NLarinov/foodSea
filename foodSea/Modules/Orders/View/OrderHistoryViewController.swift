import UIKit
import Combine

final class OrderHistoryViewController: UIViewController {
    var onOrderSelected: ((String) -> Void)?

    private let viewModel: OrderHistoryViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = UIColor.App.background
        tv.delegate = self
        tv.dataSource = self
        tv.register(OrderCell.self, forCellReuseIdentifier: OrderCell.reuseIdentifier)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 100
        return tv
    }()

    private lazy var filterScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.backgroundColor = UIColor.App.background
        return sv
    }()

    private let filterStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Constants.UI.smallPadding
        return stack
    }()

    private let emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Strings.emptyOrdersMessage
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .medium)
        label.textColor = UIColor.App.secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    init(viewModel: OrderHistoryViewModel) {
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
        setupFilters()
        bindViewModel()
        viewModel.loadOrders()
    }

    private func setupUI() {
        title = Constants.Orders.title
        view.backgroundColor = UIColor.App.background
        navigationItem.largeTitleDisplayMode = .always

        filterScrollView.addSubview(filterStack)
        filterStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            filterStack.topAnchor.constraint(equalTo: filterScrollView.topAnchor, constant: Constants.UI.smallPadding),
            filterStack.leadingAnchor.constraint(equalTo: filterScrollView.leadingAnchor, constant: Constants.UI.standardPadding),
            filterStack.trailingAnchor.constraint(equalTo: filterScrollView.trailingAnchor, constant: -Constants.UI.standardPadding),
            filterStack.bottomAnchor.constraint(equalTo: filterScrollView.bottomAnchor, constant: -Constants.UI.smallPadding),
            filterStack.heightAnchor.constraint(equalToConstant: Constants.Orders.statusFilterHeight),
        ])

        emptyStateView.addSubview(emptyLabel)
        emptyLabel.centerInSuperview()

        view.addSubview(filterScrollView)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(activityIndicator)

        filterScrollView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            filterScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            filterScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: filterScrollView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: tableView.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        activityIndicator.centerInSuperview()
    }

    private func setupFilters() {
        let allButton = makeFilterButton(title: Constants.Orders.allFilter, tag: -1)
        allButton.isSelected = true
        filterStack.addArrangedSubview(allButton)

        for (index, status) in OrderStatus.allCases.enumerated() {
            let button = makeFilterButton(title: status.displayName, tag: index)
            filterStack.addArrangedSubview(button)
        }
    }

    private func makeFilterButton(title: String, tag: Int) -> UIButton {
        var config = UIButton.Configuration.gray()
        config.title = title
        config.cornerStyle = .capsule
        config.buttonSize = .small
        let button = UIButton(configuration: config)
        button.tag = tag
        button.configurationUpdateHandler = { btn in
            var updatedConfig = btn.configuration
            updatedConfig?.baseBackgroundColor = btn.isSelected ? UIColor.App.primary : UIColor.App.secondaryBackground
            updatedConfig?.baseForegroundColor = btn.isSelected ? .white : UIColor.App.label
            btn.configuration = updatedConfig
        }
        button.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc private func filterTapped(_ sender: UIButton) {
        filterStack.arrangedSubviews
            .compactMap { $0 as? UIButton }
            .forEach { $0.isSelected = ($0 === sender) }

        if sender.tag == -1 {
            viewModel.filterByStatus(nil)
        } else {
            let status = OrderStatus.allCases[sender.tag]
            viewModel.filterByStatus(status)
        }
    }

    private func bindViewModel() {
        viewModel.$filteredOrders
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in
                self?.tableView.reloadData()
                self?.emptyStateView.isHidden = !orders.isEmpty
                self?.tableView.isHidden = orders.isEmpty
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

        viewModel.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
}

extension OrderHistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.filteredOrders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OrderCell.reuseIdentifier, for: indexPath
        ) as? OrderCell else { return UITableViewCell() }
        cell.configure(with: viewModel.filteredOrders[indexPath.row])
        return cell
    }
}

extension OrderHistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let order = viewModel.filteredOrders[indexPath.row]
        onOrderSelected?(order.id)
    }
}
