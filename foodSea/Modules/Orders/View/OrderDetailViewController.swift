import UIKit
import Combine

final class OrderDetailViewController: UIViewController {
    private let viewModel: OrderDetailViewModel
    private var cancellables = Set<AnyCancellable>()

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

    init(viewModel: OrderDetailViewModel) {
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
        viewModel.loadDetail()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.App.groupedBackground
        navigationItem.largeTitleDisplayMode = .never

        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)
        view.addSubview(activityIndicator)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: Constants.UI.standardPadding),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: Constants.UI.standardPadding),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -Constants.UI.standardPadding),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -Constants.UI.standardPadding),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -Constants.UI.standardPadding * 2),
        ])

        activityIndicator.centerInSuperview()
    }

    private func bindViewModel() {
        viewModel.$orderDetail
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detail in
                guard let self, let detail else { return }
                populateContent(detail)
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.scrollView.isHidden = loading
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

    private func populateContent(_ detail: OrderDetail) {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        title = "\(Constants.Orders.orderNumberPrefix) \(detail.order.orderNumber)"

        contentStack.addArrangedSubview(makeInfoCard(detail))
        contentStack.addArrangedSubview(makeTimelineCard(detail))
        contentStack.addArrangedSubview(makeItemsCard(detail))
        contentStack.addArrangedSubview(makeFinancialCard(detail))
    }

    private func makeInfoCard(_ detail: OrderDetail) -> UIView {
        let card = makeCard()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Constants.UI.smallPadding

        stack.addArrangedSubview(makeInfoRow("Номер:", detail.order.orderNumber))
        stack.addArrangedSubview(makeInfoRow("Дата:", Self.dateFormatter.string(from: detail.order.createdAt)))
        stack.addArrangedSubview(makeInfoRow("Статус:", detail.order.status.displayName))

        if let address = detail.deliveryAddress {
            stack.addArrangedSubview(makeInfoRow(Constants.Orders.deliveryAddressLabel + ":", address))
        }
        if let eta = detail.estimatedDelivery {
            stack.addArrangedSubview(makeInfoRow(Constants.Orders.estimatedDeliveryLabel + ":", Self.dateFormatter.string(from: eta)))
        }

        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinToSuperview(padding: Constants.UI.standardPadding)
        return card
    }

    private func makeTimelineCard(_ detail: OrderDetail) -> UIView {
        let card = makeCard()
        let timeline = StatusTimelineView()
        timeline.configure(events: detail.timeline, currentStatus: detail.order.status)

        card.addSubview(timeline)
        timeline.translatesAutoresizingMaskIntoConstraints = false
        timeline.pinToSuperview(padding: Constants.UI.standardPadding)
        return card
    }

    private func makeItemsCard(_ detail: OrderDetail) -> UIView {
        let card = makeCard()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Constants.UI.smallPadding

        let storeGroups = Dictionary(grouping: detail.order.items, by: { $0.store.name })
        for (storeName, items) in storeGroups.sorted(by: { $0.key < $1.key }) {
            let header = UILabel()
            header.text = storeName
            header.font = .systemFont(ofSize: Constants.UI.subtitleFontSize, weight: .semibold)
            header.textColor = UIColor.App.primary
            stack.addArrangedSubview(header)

            for item in items {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.minimumFractionDigits = 0
                formatter.maximumFractionDigits = 2
                let total = item.pricePerUnit * Decimal(item.quantity)
                let priceStr = formatter.string(from: NSDecimalNumber(decimal: total)) ?? "\(total)"
                let row = makeInfoRow("\(item.product.name) × \(item.quantity)", "\(priceStr) ₽")
                stack.addArrangedSubview(row)
            }
        }

        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinToSuperview(padding: Constants.UI.standardPadding)
        return card
    }

    private func makeFinancialCard(_ detail: OrderDetail) -> UIView {
        let card = makeCard()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Constants.UI.smallPadding

        let headerLabel = UILabel()
        headerLabel.text = Constants.Orders.financialSummaryHeader
        headerLabel.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .bold)
        stack.addArrangedSubview(headerLabel)

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        let totalStr = formatter.string(from: NSDecimalNumber(decimal: detail.order.totalCost)) ?? "\(detail.order.totalCost)"
        let totalRow = makeInfoRow(Constants.Optimization.grandTotalLabel, "\(totalStr) ₽")
        if let totalValue = totalRow.arrangedSubviews.last as? UILabel {
            totalValue.font = .systemFont(ofSize: Constants.UI.priceFontSize, weight: .bold)
            totalValue.textColor = UIColor.App.primary
        }
        stack.addArrangedSubview(totalRow)

        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.pinToSuperview(padding: Constants.UI.standardPadding)
        return card
    }

    private func makeCard() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.App.background
        view.layer.cornerRadius = Constants.UI.cornerRadius
        return view
    }

    private func makeInfoRow(_ title: String, _ value: String) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: Constants.UI.subtitleFontSize)
        titleLabel.textColor = UIColor.App.secondaryLabel
        titleLabel.numberOfLines = 0

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: Constants.UI.subtitleFontSize, weight: .medium)
        valueLabel.textColor = UIColor.App.label
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        row.axis = .horizontal
        row.spacing = Constants.UI.smallPadding
        row.distribution = .fillEqually
        return row
    }

    nonisolated private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy HH:mm"
        return f
    }()
}
