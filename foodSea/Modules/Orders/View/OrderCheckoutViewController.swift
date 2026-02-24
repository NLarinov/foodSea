import UIKit
import Combine

final class OrderCheckoutViewController: UIViewController {
    var onOrderCreated: ((Order) -> Void)?

    private let viewModel: OrderCheckoutViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Constants.UI.standardPadding
        return stack
    }()

    private let submitButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = Constants.Strings.submitOrder
        config.baseBackgroundColor = UIColor.App.primary
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private let bottomBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.App.secondaryBackground
        return view
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    init(viewModel: OrderCheckoutViewModel) {
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
        populateSummary()
        bindViewModel()
    }

    private func setupUI() {
        title = Constants.Orders.checkoutTitle
        view.backgroundColor = UIColor.App.groupedBackground
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(scrollView)
        view.addSubview(bottomBar)
        view.addSubview(activityIndicator)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        submitButton.setSize(height: Constants.UI.buttonHeight)
        bottomBar.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            submitButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: Constants.UI.standardPadding),
            submitButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: Constants.UI.standardPadding),
            submitButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -Constants.UI.standardPadding),
            submitButton.bottomAnchor.constraint(equalTo: bottomBar.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.UI.smallPadding),
        ])

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
    }

    private func populateSummary() {
        let result = viewModel.optimizationResult
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        let headerLabel = UILabel()
        headerLabel.text = Constants.Orders.checkoutSummaryHeader
        headerLabel.font = .systemFont(ofSize: Constants.UI.largeTitleFontSize, weight: .bold)
        contentStack.addArrangedSubview(headerLabel)

        for storeOrder in result.storeOrders {
            let card = makeCard()
            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = Constants.UI.smallPadding

            let storeLabel = UILabel()
            storeLabel.text = storeOrder.store.name
            storeLabel.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .semibold)
            storeLabel.textColor = UIColor.App.primary
            stack.addArrangedSubview(storeLabel)

            for item in storeOrder.items {
                let total = item.price * Decimal(item.quantity)
                let priceStr = formatter.string(from: NSDecimalNumber(decimal: total)) ?? "\(total)"
                let row = makeInfoRow("\(item.product.name) × \(item.quantity)", "\(priceStr) ₽")
                stack.addArrangedSubview(row)
            }

            let subtotalStr = formatter.string(from: NSDecimalNumber(decimal: storeOrder.subtotal)) ?? "\(storeOrder.subtotal)"
            stack.addArrangedSubview(makeInfoRow("Подытог:", "\(subtotalStr) ₽"))

            let deliveryStr: String
            if storeOrder.deliveryFee == 0 {
                deliveryStr = Constants.Optimization.deliveryFreeLabel
            } else {
                deliveryStr = "\(formatter.string(from: NSDecimalNumber(decimal: storeOrder.deliveryFee)) ?? "0") ₽"
            }
            stack.addArrangedSubview(makeInfoRow("Доставка:", deliveryStr))

            card.addSubview(stack)
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.pinToSuperview(padding: Constants.UI.standardPadding)
            contentStack.addArrangedSubview(card)
        }

        let totalCard = makeCard()
        let totalStack = UIStackView()
        totalStack.axis = .vertical
        totalStack.spacing = Constants.UI.smallPadding

        let grandStr = formatter.string(from: NSDecimalNumber(decimal: viewModel.grandTotal)) ?? "\(viewModel.grandTotal)"
        let grandRow = makeInfoRow(Constants.Optimization.grandTotalLabel, "\(grandStr) ₽")
        if let valueLabel = grandRow.arrangedSubviews.last as? UILabel {
            valueLabel.font = .systemFont(ofSize: Constants.UI.priceFontSize, weight: .bold)
            valueLabel.textColor = UIColor.App.primary
        }
        totalStack.addArrangedSubview(grandRow)

        totalCard.addSubview(totalStack)
        totalStack.translatesAutoresizingMaskIntoConstraints = false
        totalStack.pinToSuperview(padding: Constants.UI.standardPadding)
        contentStack.addArrangedSubview(totalCard)
    }

    private func bindViewModel() {
        viewModel.$createdOrder
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] order in
                self?.onOrderCreated?(order)
            }
            .store(in: &cancellables)

        viewModel.$isSubmitting
            .receive(on: DispatchQueue.main)
            .sink { [weak self] submitting in
                self?.submitButton.isEnabled = !submitting
                self?.scrollView.isUserInteractionEnabled = !submitting
                if submitting {
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

    @objc private func submitTapped() {
        viewModel.submitOrder()
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
}
