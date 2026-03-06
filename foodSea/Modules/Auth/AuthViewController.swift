import UIKit
import Combine

final class AuthViewController: UIViewController {
    private let viewModel: AuthViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Войти", "Регистрация"])
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private lazy var emailField: UITextField = {
        let field = UITextField()
        field.placeholder = "Email"
        field.keyboardType = .emailAddress
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.borderStyle = .roundedRect
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private lazy var passwordField: UITextField = {
        let field = UITextField()
        field.placeholder = "Пароль (минимум 8 символов)"
        field.isSecureTextEntry = true
        field.borderStyle = .roundedRect
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private lazy var submitButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Войти"
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .footnote)
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = Constants.Strings.appName

        let stack = UIStackView(arrangedSubviews: [
            segmentedControl, emailField, passwordField,
            submitButton, activityIndicator, errorLabel
        ])
        stack.axis = .vertical
        stack.spacing = Constants.UI.standardPadding
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.UI.largePadding),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.UI.largePadding),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emailField.heightAnchor.constraint(equalToConstant: Constants.UI.minimumTapSize),
            passwordField.heightAnchor.constraint(equalToConstant: Constants.UI.minimumTapSize),
            submitButton.heightAnchor.constraint(equalToConstant: Constants.UI.buttonHeight)
        ])
    }

    private func bindViewModel() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.submitButton.isEnabled = !loading
                loading ? self?.activityIndicator.startAnimating() : self?.activityIndicator.stopAnimating()
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.errorLabel.text = message
                self?.errorLabel.isHidden = message == nil
            }
            .store(in: &cancellables)

        viewModel.$mode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                self?.submitButton.configuration?.title = mode == .login ? "Войти" : "Зарегистрироваться"
            }
            .store(in: &cancellables)
    }

    @objc private func segmentChanged() {
        viewModel.mode = segmentedControl.selectedSegmentIndex == 0 ? .login : .register
    }

    @objc private func submitTapped() {
        viewModel.email = emailField.text ?? ""
        viewModel.password = passwordField.text ?? ""
        viewModel.submit()
    }
}
