import UIKit
import Combine

final class OptimizationResultsViewController: UIViewController {
    var onApply: ((OptimizationResult) -> Void)?
    var onBackToCart: (() -> Void)?

    private let viewModel: OptimizationViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.backgroundColor = UIColor.App.groupedBackground
        tv.delegate = self
        tv.dataSource = self
        tv.register(StoreOrderCell.self, forCellReuseIdentifier: StoreOrderCell.reuseIdentifier)
        tv.register(SubstitutionCell.self, forCellReuseIdentifier: SubstitutionCell.reuseIdentifier)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 120
        tv.separatorStyle = .none
        return tv
    }()

    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.App.background
        return view
    }()

    private let totalCostTitleLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Optimization.totalCostLabel
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize)
        label.textColor = UIColor.App.secondaryLabel
        return label
    }()

    private let totalCostValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize, weight: .medium)
        label.textColor = UIColor.App.label
        label.textAlignment = .right
        return label
    }()

    private let deliveryCostTitleLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Optimization.deliveryCostLabel
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize)
        label.textColor = UIColor.App.secondaryLabel
        return label
    }()

    private let deliveryCostValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize, weight: .medium)
        label.textColor = UIColor.App.label
        label.textAlignment = .right
        return label
    }()

    private let grandTotalTitleLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Optimization.grandTotalLabel
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .bold)
        label.textColor = UIColor.App.label
        return label
    }()

    private let grandTotalValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .bold)
        label.textColor = UIColor.App.primary
        label.textAlignment = .right
        return label
    }()

    private let savingsBanner: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.App.success.withAlphaComponent(0.1)
        view.layer.cornerRadius = Constants.UI.smallCornerRadius
        view.isHidden = true
        return view
    }()

    private let savingsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize, weight: .semibold)
        label.textColor = UIColor.App.success
        label.textAlignment = .center
        return label
    }()

    private let bottomBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.App.secondaryBackground
        return view
    }()

    private let applyButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = Constants.Optimization.applyButton
        config.baseBackgroundColor = UIColor.App.primary
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private let backButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = Constants.Optimization.backToCartButton
        let button = UIButton(configuration: config)
        return button
    }()

    private let loadingContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.App.background
        view.isHidden = true
        return view
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Optimization.loadingMessage
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .medium)
        label.textColor = UIColor.App.secondaryLabel
        label.textAlignment = .center
        return label
    }()

    init(viewModel: OptimizationViewModel) {
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
        viewModel.optimize()
    }

    private func setupUI() {
        title = Constants.Optimization.title
        view.backgroundColor = UIColor.App.groupedBackground
        navigationItem.largeTitleDisplayMode = .never

        savingsBanner.addSubview(savingsLabel)
        savingsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            savingsLabel.topAnchor.constraint(equalTo: savingsBanner.topAnchor, constant: Constants.UI.smallPadding),
            savingsLabel.leadingAnchor.constraint(equalTo: savingsBanner.leadingAnchor, constant: Constants.UI.standardPadding),
            savingsLabel.trailingAnchor.constraint(equalTo: savingsBanner.trailingAnchor, constant: -Constants.UI.standardPadding),
            savingsLabel.bottomAnchor.constraint(equalTo: savingsBanner.bottomAnchor, constant: -Constants.UI.smallPadding),
        ])

        let totalRow = makeRow(titleLabel: totalCostTitleLabel, valueLabel: totalCostValueLabel)
        let deliveryRow = makeRow(titleLabel: deliveryCostTitleLabel, valueLabel: deliveryCostValueLabel)
        let grandRow = makeRow(titleLabel: grandTotalTitleLabel, valueLabel: grandTotalValueLabel)

        let headerStack = UIStackView(arrangedSubviews: [totalRow, deliveryRow, grandRow, savingsBanner])
        headerStack.axis = .vertical
        headerStack.spacing = Constants.UI.smallPadding

        headerView.addSubview(headerStack)
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: headerView.topAnchor, constant: Constants.UI.standardPadding),
            headerStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: Constants.UI.standardPadding),
            headerStack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -Constants.UI.standardPadding),
            headerStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -Constants.UI.standardPadding),
        ])

        let buttonStack = UIStackView(arrangedSubviews: [applyButton, backButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = Constants.UI.smallPadding

        applyButton.setSize(height: Constants.UI.buttonHeight)

        bottomBar.addSubview(buttonStack)
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonStack.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: Constants.UI.standardPadding),
            buttonStack.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: Constants.UI.standardPadding),
            buttonStack.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -Constants.UI.standardPadding),
            buttonStack.bottomAnchor.constraint(equalTo: bottomBar.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.UI.smallPadding),
        ])

        let loadingStack = UIStackView(arrangedSubviews: [activityIndicator, loadingLabel])
        loadingStack.axis = .vertical
        loadingStack.spacing = Constants.UI.standardPadding
        loadingStack.alignment = .center

        loadingContainer.addSubview(loadingStack)
        loadingStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingStack.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor),
            loadingStack.centerYAnchor.constraint(equalTo: loadingContainer.centerYAnchor),
        ])

        view.addSubview(tableView)
        view.addSubview(bottomBar)
        view.addSubview(loadingContainer)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        loadingContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            loadingContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    private func makeRow(titleLabel: UILabel, valueLabel: UILabel) -> UIStackView {
        let row = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        row.axis = .horizontal
        row.distribution = .fillEqually
        return row
    }

    private func bindViewModel() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.loadingContainer.isHidden = !loading
                self?.tableView.isHidden = loading
                self?.bottomBar.isHidden = loading
                if loading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.$result
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self, let result else { return }
                updateHeader(with: result)
                tableView.reloadData()
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

    private func updateHeader(with result: OptimizationResult) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        totalCostValueLabel.text = "\(formatter.string(from: NSDecimalNumber(decimal: result.totalCost)) ?? "0") ₽"
        deliveryCostValueLabel.text = "\(formatter.string(from: NSDecimalNumber(decimal: result.deliveryCost)) ?? "0") ₽"

        let grand = result.totalCost + result.deliveryCost
        grandTotalValueLabel.text = "\(formatter.string(from: NSDecimalNumber(decimal: grand)) ?? "0") ₽"

        if result.savings > 0 {
            let savingsStr = formatter.string(from: NSDecimalNumber(decimal: result.savings)) ?? "0"
            savingsLabel.text = String(format: Constants.Optimization.savingsFormat, savingsStr)
            savingsBanner.isHidden = false
        } else {
            savingsBanner.isHidden = true
        }

        let headerHeight = headerView.systemLayoutSizeFitting(
            CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: headerHeight)
        tableView.tableHeaderView = headerView
    }

    @objc private func applyTapped() {
        guard let result = viewModel.result else { return }
        onApply?(result)
    }

    @objc private func backTapped() {
        onBackToCart?()
    }
}

extension OptimizationResultsViewController: UITableViewDataSource {
    nonisolated enum Section: Int, CaseIterable, Sendable {
        case storeOrders
        case substitutions
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let result = viewModel.result else { return 0 }
        switch Section(rawValue: section) {
        case .storeOrders: return result.storeOrders.count
        case .substitutions: return result.substitutions.count
        case .none: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let result = viewModel.result else { return UITableViewCell() }

        switch Section(rawValue: indexPath.section) {
        case .storeOrders:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: StoreOrderCell.reuseIdentifier, for: indexPath
            ) as? StoreOrderCell else { return UITableViewCell() }
            cell.configure(with: result.storeOrders[indexPath.row])
            return cell

        case .substitutions:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SubstitutionCell.reuseIdentifier, for: indexPath
            ) as? SubstitutionCell else { return UITableViewCell() }
            let sub = result.substitutions[indexPath.row]
            cell.configure(with: sub)
            cell.onAccept = { [weak self] in
                self?.viewModel.acceptSubstitution(id: sub.id)
            }
            cell.onReject = { [weak self] in
                self?.viewModel.rejectSubstitution(id: sub.id)
            }
            return cell

        case .none:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard viewModel.result != nil else { return nil }
        switch Section(rawValue: section) {
        case .storeOrders: return Constants.Optimization.storeOrdersSection
        case .substitutions: return Constants.Optimization.substitutionsSection
        case .none: return nil
        }
    }
}

extension OptimizationResultsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if Section(rawValue: indexPath.section) == .storeOrders {
            guard let cell = tableView.cellForRow(at: indexPath) as? StoreOrderCell else { return }
            cell.toggleExpansion()
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
}
