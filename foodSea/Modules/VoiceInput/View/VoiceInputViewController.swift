import UIKit
import Combine

final class VoiceInputViewController: UIViewController {
    var onAddedToCart: (() -> Void)?
    var onClose: (() -> Void)?

    private let viewModel: VoiceInputViewModel
    private var cancellables = Set<AnyCancellable>()
    private var pulseLayer: CAShapeLayer?

    private let micButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .medium)
        button.setImage(UIImage(systemName: "mic.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.App.primary
        button.layer.cornerRadius = Constants.Voice.micButtonSize / 2
        button.clipsToBounds = true
        return button
    }()

    private let stateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .medium)
        label.textColor = UIColor.App.label
        label.textAlignment = .center
        return label
    }()

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Strings.voiceHint
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize)
        label.textColor = UIColor.App.secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: Constants.UI.titleFontSize, weight: .medium)
        label.textColor = UIColor.App.primary
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private let partialTranscriptLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.UI.subtitleFontSize)
        label.textColor = UIColor.App.label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = UIColor.App.background
        tv.delegate = self
        tv.dataSource = self
        tv.register(RecognizedProductCell.self, forCellReuseIdentifier: RecognizedProductCell.reuseIdentifier)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = Constants.UI.thumbnailSize + Constants.UI.standardPadding
        tv.isHidden = true
        tv.separatorInset = UIEdgeInsets(
            top: 0,
            left: Constants.UI.separatorInset,
            bottom: 0,
            right: Constants.UI.separatorInset
        )
        return tv
    }()

    private let addAllButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = Constants.Strings.addAllToCart
        config.baseBackgroundColor = UIColor.App.primary
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.isHidden = true
        return button
    }()

    private let retryButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = Constants.Strings.retry
        config.baseBackgroundColor = UIColor.App.secondary
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.isHidden = true
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    init(viewModel: VoiceInputViewModel) {
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

    private func setupUI() {
        title = Constants.Strings.voiceTitle
        view.backgroundColor = UIColor.App.background

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: Constants.Strings.closeButton,
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )

        let topStack = UIStackView(arrangedSubviews: [stateLabel, hintLabel, durationLabel, partialTranscriptLabel])
        topStack.axis = .vertical
        topStack.spacing = Constants.UI.smallPadding
        topStack.alignment = .center

        view.addSubview(topStack)
        view.addSubview(micButton)
        view.addSubview(tableView)
        view.addSubview(addAllButton)
        view.addSubview(retryButton)
        view.addSubview(activityIndicator)

        topStack.translatesAutoresizingMaskIntoConstraints = false
        micButton.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addAllButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topStack.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: Constants.UI.largePadding
            ),
            topStack.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constants.UI.standardPadding
            ),
            topStack.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constants.UI.standardPadding
            ),

            micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micButton.topAnchor.constraint(
                equalTo: topStack.bottomAnchor,
                constant: Constants.UI.largePadding
            ),
            micButton.widthAnchor.constraint(equalToConstant: Constants.Voice.micButtonSize),
            micButton.heightAnchor.constraint(equalToConstant: Constants.Voice.micButtonSize),

            tableView.topAnchor.constraint(
                equalTo: micButton.bottomAnchor,
                constant: Constants.UI.largePadding
            ),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(
                equalTo: addAllButton.topAnchor,
                constant: -Constants.UI.standardPadding
            ),

            addAllButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constants.UI.standardPadding
            ),
            addAllButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constants.UI.standardPadding
            ),
            addAllButton.heightAnchor.constraint(equalToConstant: Constants.UI.buttonHeight),
            addAllButton.bottomAnchor.constraint(
                equalTo: retryButton.topAnchor,
                constant: -Constants.UI.smallPadding
            ),

            retryButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constants.UI.standardPadding
            ),
            retryButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constants.UI.standardPadding
            ),
            retryButton.heightAnchor.constraint(equalToConstant: Constants.UI.buttonHeight),
            retryButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -Constants.UI.standardPadding
            ),
        ])

        activityIndicator.centerInSuperview()

        micButton.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        addAllButton.addTarget(self, action: #selector(addAllTapped), for: .touchUpInside)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        updateIdleState()
    }

    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleState(state)
            }
            .store(in: &cancellables)

        viewModel.$recognizedProducts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$recordingDuration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] duration in
                let minutes = Int(duration) / 60
                let seconds = Int(duration) % 60
                self?.durationLabel.text = String(format: "%d:%02d", minutes, seconds)
            }
            .store(in: &cancellables)
    }

    private func handleState(_ state: VoiceInputState) {
        switch state {
        case .idle:
            updateIdleState()
        case .listening(let partialText):
            updateListeningState(partialText: partialText)
        case .processing:
            updateProcessingState()
        case .results:
            updateResultsState()
        case .error(let error):
            updateIdleState()
            showError(error)
        }
    }

    private func updateIdleState() {
        stateLabel.text = Constants.Strings.voiceTitle
        hintLabel.isHidden = false
        durationLabel.isHidden = true
        partialTranscriptLabel.isHidden = true
        tableView.isHidden = true
        addAllButton.isHidden = true
        retryButton.isHidden = true
        activityIndicator.stopAnimating()
        micButton.isHidden = false
        micButton.backgroundColor = UIColor.App.primary
        stopPulseAnimation()

        let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .medium)
        micButton.setImage(UIImage(systemName: "mic.fill", withConfiguration: config), for: .normal)
    }

    private func updateListeningState(partialText: String) {
        stateLabel.text = Constants.Strings.voiceRecording
        hintLabel.isHidden = true
        durationLabel.isHidden = false
        partialTranscriptLabel.isHidden = partialText.isEmpty
        partialTranscriptLabel.text = partialText
        tableView.isHidden = true
        addAllButton.isHidden = true
        retryButton.isHidden = true
        micButton.isHidden = false
        micButton.backgroundColor = UIColor.App.error
        startPulseAnimation()

        let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .medium)
        micButton.setImage(UIImage(systemName: "stop.fill", withConfiguration: config), for: .normal)
    }

    private func updateProcessingState() {
        stateLabel.text = Constants.Strings.voiceProcessing
        hintLabel.isHidden = true
        durationLabel.isHidden = true
        partialTranscriptLabel.isHidden = true
        micButton.isHidden = true
        tableView.isHidden = true
        addAllButton.isHidden = true
        retryButton.isHidden = true
        activityIndicator.startAnimating()
        stopPulseAnimation()
    }

    private func updateResultsState() {
        stateLabel.text = Constants.Strings.voiceTitle
        hintLabel.isHidden = true
        durationLabel.isHidden = true
        partialTranscriptLabel.isHidden = true
        micButton.isHidden = true
        tableView.isHidden = false
        addAllButton.isHidden = false
        retryButton.isHidden = false
        activityIndicator.stopAnimating()
        stopPulseAnimation()
    }

    private func startPulseAnimation() {
        let pulse = CAShapeLayer()
        pulse.path = UIBezierPath(
            ovalIn: CGRect(
                x: -Constants.UI.smallPadding,
                y: -Constants.UI.smallPadding,
                width: Constants.Voice.micButtonSize + Constants.UI.standardPadding,
                height: Constants.Voice.micButtonSize + Constants.UI.standardPadding
            )
        ).cgPath
        pulse.fillColor = UIColor.App.error.withAlphaComponent(0.3).cgColor
        micButton.layer.insertSublayer(pulse, at: 0)
        pulseLayer = pulse

        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1.0
        animation.toValue = Constants.Voice.pulseScale
        animation.duration = Constants.Voice.pulseAnimationDuration
        animation.autoreverses = true
        animation.repeatCount = .infinity
        pulse.add(animation, forKey: "pulse")
    }

    private func stopPulseAnimation() {
        pulseLayer?.removeAllAnimations()
        pulseLayer?.removeFromSuperlayer()
        pulseLayer = nil
    }

    @objc private func micTapped() {
        switch viewModel.state {
        case .idle, .results, .error:
            viewModel.startRecording()
        case .listening:
            viewModel.stopRecording()
        case .processing:
            break
        }
    }

    @objc private func addAllTapped() {
        viewModel.addAllToCart()
        onAddedToCart?()
    }

    @objc private func retryTapped() {
        viewModel.reset()
        viewModel.startRecording()
    }

    @objc private func closeTapped() {
        onClose?()
    }
}

extension VoiceInputViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.recognizedProducts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: RecognizedProductCell.reuseIdentifier,
            for: indexPath
        ) as? RecognizedProductCell else {
            return UITableViewCell()
        }

        let item = viewModel.recognizedProducts[indexPath.row]
        cell.configure(with: item)
        cell.onQuantityChanged = { [weak self] quantity in
            self?.viewModel.updateQuantity(index: indexPath.row, quantity: quantity)
        }
        cell.onRemove = { [weak self] in
            self?.viewModel.removeProduct(index: indexPath.row)
        }
        return cell
    }
}

extension VoiceInputViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
