import UIKit

final class OrderConfirmationViewController: UIViewController {
    var onGoToOrders: (() -> Void)?
    var onGoToCatalog: (() -> Void)?

    private let order: Order

    private let successImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark.circle.fill")
        iv.tintColor = UIColor.App.success
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Orders.confirmationTitle
        label.font = .systemFont(ofSize: Constants.UI.largeTitleFontSize, weight: .bold)
        label.textColor = UIColor.App.label
        label.textAlignment = .center
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Orders.confirmationMessage
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize)
        label.textColor = UIColor.App.secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let orderNumberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .medium)
        label.textColor = UIColor.App.primary
        label.textAlignment = .center
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize)
        label.textColor = UIColor.App.secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let goToOrdersButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = Constants.Strings.toOrders
        config.baseBackgroundColor = UIColor.App.primary
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private let goToCatalogButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = Constants.Strings.toCatalog
        let button = UIButton(configuration: config)
        return button
    }()

    init(order: Order) {
        self.order = order
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureData()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.App.background
        navigationItem.hidesBackButton = true
        navigationItem.largeTitleDisplayMode = .never

        successImageView.setSize(width: 80, height: 80)
        goToOrdersButton.setSize(height: Constants.UI.buttonHeight)

        let stack = UIStackView(arrangedSubviews: [
            successImageView, titleLabel, messageLabel,
            orderNumberLabel, statusLabel,
            UIView(),
            goToOrdersButton, goToCatalogButton,
        ])
        stack.axis = .vertical
        stack.spacing = Constants.UI.standardPadding
        stack.alignment = .center

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.UI.largePadding),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.UI.largePadding),
            goToOrdersButton.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            goToOrdersButton.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
        ])

        goToOrdersButton.addTarget(self, action: #selector(goToOrdersTapped), for: .touchUpInside)
        goToCatalogButton.addTarget(self, action: #selector(goToCatalogTapped), for: .touchUpInside)
    }

    private func configureData() {
        orderNumberLabel.text = order.orderNumber
        statusLabel.text = order.status.displayName
    }

    @objc private func goToOrdersTapped() {
        onGoToOrders?()
    }

    @objc private func goToCatalogTapped() {
        onGoToCatalog?()
    }
}
