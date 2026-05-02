import UIKit
import Combine

final class WelcomeViewController: UIViewController {
    private let viewModel: WelcomeViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Strings.appName
        label.font = .systemFont(ofSize: Constants.UI.largeTitleFontSize, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Strings.welcomeSubtitle
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var appleButton = Self.makeOAuthButton(
        title: Constants.Strings.signInWithApple,
        icon: UIImage(systemName: "apple.logo"),
        background: .label,
        foreground: .systemBackground,
        target: self,
        action: #selector(appleTapped)
    )

    private lazy var googleButton = Self.makeOAuthButton(
        title: Constants.Strings.signInWithGoogle,
        icon: UIImage(systemName: "g.circle.fill"),
        background: .systemBackground,
        foreground: .label,
        target: self,
        action: #selector(googleTapped)
    )

    private lazy var yandexButton = Self.makeOAuthButton(
        title: Constants.Strings.signInWithYandex,
        icon: UIImage(systemName: "y.circle.fill"),
        background: .systemRed,
        foreground: .white,
        target: self,
        action: #selector(yandexTapped)
    )

    private lazy var separatorLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Strings.orSeparator
        label.font = .systemFont(ofSize: Constants.UI.captionFontSize)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var emailButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = Constants.Strings.signInWithEmail
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(emailTapped), for: .touchUpInside)
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

    init(viewModel: WelcomeViewModel) {
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
        navigationItem.title = nil

        let buttonsStack = UIStackView(arrangedSubviews: [appleButton, googleButton, yandexButton])
        buttonsStack.axis = .vertical
        buttonsStack.spacing = Constants.UI.cellSpacing

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            buttonsStack,
            separatorLabel,
            emailButton,
            activityIndicator,
            errorLabel
        ])
        stack.axis = .vertical
        stack.spacing = Constants.UI.standardPadding
        stack.setCustomSpacing(Constants.UI.smallPadding, after: titleLabel)
        stack.setCustomSpacing(Constants.UI.largePadding, after: subtitleLabel)
        stack.setCustomSpacing(Constants.UI.largePadding, after: buttonsStack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.UI.largePadding),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.UI.largePadding),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            appleButton.heightAnchor.constraint(equalToConstant: Constants.UI.buttonHeight),
            googleButton.heightAnchor.constraint(equalToConstant: Constants.UI.buttonHeight),
            yandexButton.heightAnchor.constraint(equalToConstant: Constants.UI.buttonHeight)
        ])
    }

    private func bindViewModel() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.setControlsEnabled(!loading)
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
    }

    private func setControlsEnabled(_ enabled: Bool) {
        [appleButton, googleButton, yandexButton, emailButton].forEach { $0.isEnabled = enabled }
    }

    @objc private func appleTapped()  { viewModel.signInWithApple() }
    @objc private func googleTapped() { viewModel.signInWithGoogle() }
    @objc private func yandexTapped() { viewModel.signInWithYandex() }
    @objc private func emailTapped()  { viewModel.continueWithEmail() }

    private static func makeOAuthButton(title: String,
                                        icon: UIImage?,
                                        background: UIColor,
                                        foreground: UIColor,
                                        target: Any,
                                        action: Selector) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = icon
        config.imagePadding = Constants.UI.smallPadding
        config.baseBackgroundColor = background
        config.baseForegroundColor = foreground
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}
