import UIKit
import Combine

final class FilterViewController: UIViewController {
    var onApply: ((SearchFilters) -> Void)?

    private let viewModel: FilterViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Constants.UI.standardPadding
        return stack
    }()

    private let categoriesLabel: UILabel = {
        let label = UILabel()
        label.text = "Категории"
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .semibold)
        label.textColor = UIColor.App.label
        return label
    }()

    private let categoriesStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Constants.UI.smallPadding
        return stack
    }()

    private let brandsLabel: UILabel = {
        let label = UILabel()
        label.text = "Бренды"
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .semibold)
        label.textColor = UIColor.App.label
        return label
    }()

    private let brandsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Constants.UI.smallPadding
        return stack
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.text = "Цена"
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .semibold)
        label.textColor = UIColor.App.label
        return label
    }()

    private let minPriceField: UITextField = {
        let field = UITextField()
        field.placeholder = "от"
        field.borderStyle = .roundedRect
        field.keyboardType = .decimalPad
        return field
    }()

    private let maxPriceField: UITextField = {
        let field = UITextField()
        field.placeholder = "до"
        field.borderStyle = .roundedRect
        field.keyboardType = .decimalPad
        return field
    }()

    private let applyButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = Constants.Strings.applyFilters
        config.baseBackgroundColor = UIColor.App.primary
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private let resetButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = Constants.Strings.resetFilters
        config.baseForegroundColor = UIColor.App.secondary
        let button = UIButton(configuration: config)
        return button
    }()

    init(viewModel: FilterViewModel) {
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
        populateFilters()
        bindViewModel()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.App.background

        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.distribution = .equalSpacing

        let titleLabel = UILabel()
        titleLabel.text = "Фильтры"
        titleLabel.font = .systemFont(ofSize: Constants.UI.largeTitleFontSize, weight: .bold)
        titleLabel.textColor = UIColor.App.label

        let closeButton = UIButton(type: .close)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(closeButton)

        let priceStack = UIStackView(arrangedSubviews: [minPriceField, maxPriceField])
        priceStack.axis = .horizontal
        priceStack.spacing = Constants.UI.smallPadding
        priceStack.distribution = .fillEqually

        let buttonsStack = UIStackView(arrangedSubviews: [resetButton, applyButton])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = Constants.UI.smallPadding
        buttonsStack.distribution = .fillEqually

        applyButton.setSize(height: Constants.UI.buttonHeight)

        contentStack.addArrangedSubview(headerStack)
        contentStack.addArrangedSubview(categoriesLabel)
        contentStack.addArrangedSubview(categoriesStack)
        contentStack.addArrangedSubview(brandsLabel)
        contentStack.addArrangedSubview(brandsStack)
        contentStack.addArrangedSubview(priceLabel)
        contentStack.addArrangedSubview(priceStack)
        contentStack.addArrangedSubview(buttonsStack)

        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: Constants.UI.standardPadding),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: Constants.UI.standardPadding),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -Constants.UI.standardPadding),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -Constants.UI.standardPadding),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -Constants.UI.standardPadding * 2),
        ])

        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
    }

    private func populateFilters() {
        for category in viewModel.availableCategories {
            let button = makeCheckButton(
                title: category.name,
                isSelected: viewModel.selectedCategories.contains(category.id)
            )
            button.tag = viewModel.availableCategories.firstIndex(where: { $0.id == category.id }) ?? 0
            button.addTarget(self, action: #selector(categoryToggled(_:)), for: .touchUpInside)
            categoriesStack.addArrangedSubview(button)
        }

        for (index, brand) in viewModel.availableBrands.enumerated() {
            let button = makeCheckButton(
                title: brand,
                isSelected: viewModel.selectedBrands.contains(brand)
            )
            button.tag = index
            button.addTarget(self, action: #selector(brandToggled(_:)), for: .touchUpInside)
            brandsStack.addArrangedSubview(button)
        }

        if let minPrice = viewModel.minPrice {
            minPriceField.text = "\(minPrice)"
        }
        if let maxPrice = viewModel.maxPrice {
            maxPriceField.text = "\(maxPrice)"
        }
    }

    private func bindViewModel() {
        viewModel.$selectedCategories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selected in
                self?.updateCategoryButtons(selected: selected)
            }
            .store(in: &cancellables)

        viewModel.$selectedBrands
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selected in
                self?.updateBrandButtons(selected: selected)
            }
            .store(in: &cancellables)
    }

    private func makeCheckButton(title: String, isSelected: Bool) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = UIColor.App.label
        config.image = UIImage(systemName: isSelected ? "checkmark.square.fill" : "square")
        config.imagePadding = Constants.UI.smallPadding
        config.contentInsets = NSDirectionalEdgeInsets(
            top: Constants.UI.smallPadding,
            leading: 0,
            bottom: Constants.UI.smallPadding,
            trailing: 0
        )
        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .leading
        return button
    }

    private func updateCategoryButtons(selected: Set<String>) {
        for (index, view) in categoriesStack.arrangedSubviews.enumerated() {
            guard let button = view as? UIButton, index < viewModel.availableCategories.count else { continue }
            let categoryId = viewModel.availableCategories[index].id
            let isSelected = selected.contains(categoryId)
            button.configuration?.image = UIImage(systemName: isSelected ? "checkmark.square.fill" : "square")
        }
    }

    private func updateBrandButtons(selected: Set<String>) {
        for (index, view) in brandsStack.arrangedSubviews.enumerated() {
            guard let button = view as? UIButton, index < viewModel.availableBrands.count else { continue }
            let brand = viewModel.availableBrands[index]
            let isSelected = selected.contains(brand)
            button.configuration?.image = UIImage(systemName: isSelected ? "checkmark.square.fill" : "square")
        }
    }

    @objc private func categoryToggled(_ sender: UIButton) {
        guard sender.tag < viewModel.availableCategories.count else { return }
        let categoryId = viewModel.availableCategories[sender.tag].id
        viewModel.toggleCategory(categoryId)
    }

    @objc private func brandToggled(_ sender: UIButton) {
        guard sender.tag < viewModel.availableBrands.count else { return }
        let brand = viewModel.availableBrands[sender.tag]
        viewModel.toggleBrand(brand)
    }

    @objc private func applyTapped() {
        if let text = minPriceField.text, !text.isEmpty {
            viewModel.minPrice = Decimal(string: text)
        } else {
            viewModel.minPrice = nil
        }
        if let text = maxPriceField.text, !text.isEmpty {
            viewModel.maxPrice = Decimal(string: text)
        } else {
            viewModel.maxPrice = nil
        }

        let filters = viewModel.apply()
        onApply?(filters)
        dismiss(animated: true)
    }

    @objc private func resetTapped() {
        viewModel.reset()
        minPriceField.text = nil
        maxPriceField.text = nil
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
