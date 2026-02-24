import UIKit
import AVFoundation
import Combine

final class BarcodeScannerViewController: UIViewController {
    var onProductFound: ((Product) -> Void)?
    var onClose: (() -> Void)?

    private let viewModel: BarcodeScannerViewModel
    private var cancellables = Set<AnyCancellable>()
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(Constants.Scanner.overlayAlpha)
        return view
    }()

    private let targetRect: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = Constants.UI.cornerRadius
        return view
    }()

    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Strings.scannerHint
        label.textColor = .white
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let manualEntryButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = Constants.Strings.manualEntry
        config.baseBackgroundColor = UIColor.App.primary
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    init(viewModel: BarcodeScannerViewModel) {
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
        checkCameraPermission()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updateOverlayMask()
    }

    private func setupUI() {
        title = Constants.Strings.scannerTitle
        view.backgroundColor = .black

        view.addSubview(overlayView)
        overlayView.addSubview(targetRect)
        overlayView.addSubview(instructionLabel)
        view.addSubview(closeButton)
        view.addSubview(activityIndicator)
        view.addSubview(manualEntryButton)

        overlayView.translatesAutoresizingMaskIntoConstraints = false
        targetRect.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        manualEntryButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            targetRect.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            targetRect.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            targetRect.widthAnchor.constraint(equalToConstant: Constants.Scanner.targetRectSize),
            targetRect.heightAnchor.constraint(equalToConstant: Constants.Scanner.targetRectSize),

            instructionLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            instructionLabel.topAnchor.constraint(
                equalTo: targetRect.bottomAnchor,
                constant: Constants.UI.largePadding
            ),
            instructionLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: overlayView.leadingAnchor,
                constant: Constants.UI.standardPadding
            ),

            closeButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: Constants.UI.standardPadding
            ),
            closeButton.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: Constants.UI.standardPadding
            ),
            closeButton.widthAnchor.constraint(equalToConstant: Constants.UI.minimumTapSize),
            closeButton.heightAnchor.constraint(equalToConstant: Constants.UI.minimumTapSize),

            manualEntryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            manualEntryButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -Constants.UI.largePadding
            ),
            manualEntryButton.heightAnchor.constraint(equalToConstant: Constants.UI.buttonHeight),
            manualEntryButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constants.UI.largePadding
            ),
            manualEntryButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constants.UI.largePadding
            ),
        ])

        activityIndicator.centerInSuperview()

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        manualEntryButton.addTarget(self, action: #selector(manualEntryTapped), for: .touchUpInside)
    }

    private func updateOverlayMask() {
        let path = UIBezierPath(rect: overlayView.bounds)
        let targetFrame = targetRect.frame
        let cutout = UIBezierPath(roundedRect: targetFrame, cornerRadius: Constants.UI.cornerRadius)
        path.append(cutout)
        path.usesEvenOddFillRule = true

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer
    }

    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleState(state)
            }
            .store(in: &cancellables)

        viewModel.$isProcessing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] processing in
                if processing {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
    }

    private func handleState(_ state: BarcodeScannerState) {
        switch state {
        case .idle, .scanning:
            break
        case .found(let product):
            stopScanning()
            onProductFound?(product)
        case .notFound:
            stopScanning()
            showNotFoundAlert()
        case .error(let error):
            showError(error)
        }
    }

    private func showNotFoundAlert() {
        let alert = UIAlertController(
            title: Constants.Strings.productNotFound,
            message: nil,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Constants.Strings.manualEntry, style: .default) { [weak self] _ in
            self?.showManualEntryAlert()
        })
        alert.addAction(UIAlertAction(title: Constants.Strings.retry, style: .default) { [weak self] _ in
            self?.startScanning()
        })
        alert.addAction(UIAlertAction(title: Constants.Strings.cancel, style: .cancel) { [weak self] _ in
            self?.startScanning()
        })
        present(alert, animated: true)
    }

    private func showManualEntryAlert() {
        let alert = UIAlertController(
            title: Constants.Strings.scannerTitle,
            message: nil,
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = Constants.Scanner.manualEntryPlaceholder
            textField.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: Constants.Strings.cancel, style: .cancel) { [weak self] _ in
            self?.startScanning()
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let barcode = alert.textFields?.first?.text, !barcode.isEmpty else {
                self?.startScanning()
                return
            }
            self?.viewModel.lookup(barcode: barcode)
        })
        present(alert, animated: true)
    }

    private func checkCameraPermission() {
        #if targetEnvironment(simulator)
        showManualEntryAlert()
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.showManualEntryAlert()
                    }
                }
            }
        default:
            showManualEntryAlert()
        }
        #endif
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            showManualEntryAlert()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128]
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)

        self.captureSession = session
        self.previewLayer = preview
        startScanning()
    }

    private func startScanning() {
        viewModel.state = .scanning
        Task.detached { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    private func stopScanning() {
        Task.detached { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    @objc private func closeTapped() {
        stopScanning()
        onClose?()
    }

    @objc private func manualEntryTapped() {
        stopScanning()
        showManualEntryAlert()
    }
}

extension BarcodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let barcode = metadata.stringValue else { return }

        Task { @MainActor in
            stopScanning()
            viewModel.lookup(barcode: barcode)
        }
    }
}
