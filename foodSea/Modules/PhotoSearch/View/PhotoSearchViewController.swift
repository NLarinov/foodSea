import UIKit
import AVFoundation
import Combine
import PhotosUI

final class PhotoSearchViewController: UIViewController {
    var onProductFound: ((Product) -> Void)?
    var onClose: (() -> Void)?

    private let viewModel: PhotoSearchViewModel
    private var cancellables = Set<AnyCancellable>()

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var captureDevice: AVCaptureDevice?

    private let frozenFrameView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isHidden = true
        return iv
    }()

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.Strings.photoSearchHint
        label.textColor = .white
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.backgroundColor = UIColor.black.withAlphaComponent(Constants.PhotoSearch.hintBackgroundAlpha)
        label.layer.cornerRadius = Constants.UI.cornerRadius
        label.layer.masksToBounds = true
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        return button
    }()

    private let bottomPanel: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(Constants.PhotoSearch.bottomPanelBackgroundAlpha)
        return view
    }()

    private let galleryButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = Constants.Strings.photoSearchGallery
        config.baseForegroundColor = .white
        let button = UIButton(configuration: config)
        return button
    }()

    private let shutterButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = Constants.PhotoSearch.shutterButtonSize / 2
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        return button
    }()

    private let torchButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        button.setImage(UIImage(systemName: "bolt.slash.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.isHidden = true
        return button
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let resultOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(Constants.PhotoSearch.resultOverlayAlpha)
        view.isHidden = true
        return view
    }()

    private let resultLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let retryButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = Constants.Strings.photoSearchTryAgain
        config.baseBackgroundColor = UIColor.App.primary
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    init(viewModel: PhotoSearchViewModel) {
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
        viewModel.onProductFound = { [weak self] product in
            self?.handleProductFound(product)
        }
        checkCameraAvailability()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupUI() {
        view.backgroundColor = .black

        view.addSubview(frozenFrameView)
        frozenFrameView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            frozenFrameView.topAnchor.constraint(equalTo: view.topAnchor),
            frozenFrameView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            frozenFrameView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            frozenFrameView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        [hintLabel, closeButton, bottomPanel, activityIndicator, resultOverlay].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        [galleryButton, shutterButton, torchButton].forEach {
            bottomPanel.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        [resultLabel, retryButton].forEach {
            resultOverlay.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            hintLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: Constants.PhotoSearch.hintTopOffset
            ),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.UI.largePadding),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.UI.largePadding),
            hintLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.UI.minimumTapSize),

            closeButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: Constants.UI.smallPadding
            ),
            closeButton.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -Constants.UI.standardPadding
            ),
            closeButton.widthAnchor.constraint(equalToConstant: Constants.UI.minimumTapSize),
            closeButton.heightAnchor.constraint(equalToConstant: Constants.UI.minimumTapSize),

            bottomPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomPanel.heightAnchor.constraint(equalToConstant: Constants.PhotoSearch.bottomPanelHeight),

            shutterButton.centerXAnchor.constraint(equalTo: bottomPanel.centerXAnchor),
            shutterButton.centerYAnchor.constraint(
                equalTo: bottomPanel.safeAreaLayoutGuide.centerYAnchor
            ),
            shutterButton.widthAnchor.constraint(equalToConstant: Constants.PhotoSearch.shutterButtonSize),
            shutterButton.heightAnchor.constraint(equalToConstant: Constants.PhotoSearch.shutterButtonSize),

            galleryButton.leadingAnchor.constraint(
                equalTo: bottomPanel.leadingAnchor,
                constant: Constants.UI.standardPadding
            ),
            galleryButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            galleryButton.heightAnchor.constraint(equalToConstant: Constants.UI.minimumTapSize),

            torchButton.trailingAnchor.constraint(
                equalTo: bottomPanel.trailingAnchor,
                constant: -Constants.UI.largePadding
            ),
            torchButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            torchButton.widthAnchor.constraint(equalToConstant: Constants.PhotoSearch.controlButtonSize),
            torchButton.heightAnchor.constraint(equalToConstant: Constants.PhotoSearch.controlButtonSize),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            resultOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            resultOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            resultLabel.centerXAnchor.constraint(equalTo: resultOverlay.centerXAnchor),
            resultLabel.centerYAnchor.constraint(
                equalTo: resultOverlay.centerYAnchor,
                constant: -Constants.UI.largePadding
            ),
            resultLabel.leadingAnchor.constraint(
                equalTo: resultOverlay.leadingAnchor,
                constant: Constants.UI.largePadding
            ),
            resultLabel.trailingAnchor.constraint(
                equalTo: resultOverlay.trailingAnchor,
                constant: -Constants.UI.largePadding
            ),

            retryButton.centerXAnchor.constraint(equalTo: resultOverlay.centerXAnchor),
            retryButton.topAnchor.constraint(
                equalTo: resultLabel.bottomAnchor,
                constant: Constants.UI.largePadding
            ),
            retryButton.heightAnchor.constraint(equalToConstant: Constants.UI.buttonHeight),
            retryButton.widthAnchor.constraint(greaterThanOrEqualToConstant: Constants.PhotoSearch.bottomPanelHeight * 2),
        ])

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        shutterButton.addTarget(self, action: #selector(shutterTapped), for: .touchUpInside)
        galleryButton.addTarget(self, action: #selector(galleryTapped), for: .touchUpInside)
        torchButton.addTarget(self, action: #selector(torchTapped), for: .touchUpInside)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
    }

    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handle(state: state)
            }
            .store(in: &cancellables)
    }

    private func handle(state: PhotoSearchState) {
        switch state {
        case .idle:
            activityIndicator.stopAnimating()
            resultOverlay.isHidden = true
            unfreezeFrame()
            setControlsEnabled(true)
        case .processing:
            activityIndicator.startAnimating()
            resultOverlay.isHidden = true
            setControlsEnabled(false)
        case .notFound:
            activityIndicator.stopAnimating()
            resultLabel.text = Constants.Strings.productNotFound
            resultOverlay.isHidden = false
            setControlsEnabled(false)
        case .failed(let error):
            activityIndicator.stopAnimating()
            resultLabel.text = error.errorDescription ?? Constants.Strings.serverError
            resultOverlay.isHidden = false
            setControlsEnabled(false)
        }
    }

    private func setControlsEnabled(_ enabled: Bool) {
        shutterButton.isEnabled = enabled
        galleryButton.isEnabled = enabled
        torchButton.isEnabled = enabled
    }

    private func freezeFrame(_ image: UIImage) {
        frozenFrameView.image = image
        frozenFrameView.isHidden = false
        previewLayer?.connection?.isEnabled = false
    }

    private func unfreezeFrame() {
        frozenFrameView.isHidden = true
        frozenFrameView.image = nil
        previewLayer?.connection?.isEnabled = true
    }

    private func handleProductFound(_ product: Product) {
        stopSession()
        onProductFound?(product)
    }

    private func checkCameraAvailability() {
        #if targetEnvironment(simulator)
        presentCameraUnavailableAlert()
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
                        self?.presentCameraUnavailableAlert()
                    }
                }
            }
        default:
            presentCameraUnavailableAlert()
        }
        #endif
    }

    private func presentCameraUnavailableAlert() {
        let alert = UIAlertController(
            title: Constants.Strings.photoSearchCameraUnavailable,
            message: Constants.Strings.photoSearchCameraUnavailableMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Constants.Strings.photoSearchGallery, style: .default) { [weak self] _ in
            self?.presentGalleryPicker()
        })
        alert.addAction(UIAlertAction(title: Constants.Strings.cancel, style: .cancel) { [weak self] _ in
            self?.closeTapped()
        })
        present(alert, animated: true)
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            presentCameraUnavailableAlert()
            return
        }

        if session.canAddInput(input) { session.addInput(input) }

        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) { session.addOutput(output) }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)

        self.captureSession = session
        self.photoOutput = output
        self.previewLayer = preview
        self.captureDevice = device

        torchButton.isHidden = !device.hasTorch

        Task.detached { session.startRunning() }
    }

    private func stopSession() {
        guard let session = captureSession else { return }
        Task.detached { session.stopRunning() }
    }

    @objc private func closeTapped() {
        stopSession()
        onClose?()
    }

    @objc private func shutterTapped() {
        guard let output = photoOutput else { return }
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        output.capturePhoto(with: settings, delegate: self)
    }

    @objc private func galleryTapped() {
        presentGalleryPicker()
    }

    @objc private func torchTapped() {
        guard let device = captureDevice, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            let newMode: AVCaptureDevice.TorchMode = (device.torchMode == .on) ? .off : .on
            device.torchMode = newMode
            device.unlockForConfiguration()
            let imageName = newMode == .on ? "bolt.fill" : "bolt.slash.fill"
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            torchButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
        } catch {
            // ignore — torch toggling is non-critical
        }
    }

    @objc private func retryTapped() {
        viewModel.reset()
    }

    private func presentGalleryPicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func compressForUpload(_ image: UIImage) -> Data? {
        var quality = Constants.PhotoSearch.initialJPEGQuality
        var data = image.jpegData(compressionQuality: quality)
        while let current = data,
              current.count > Constants.PhotoSearch.targetCompressionBytes,
              quality > Constants.PhotoSearch.minJPEGQuality {
            quality -= Constants.PhotoSearch.jpegQualityStep
            data = image.jpegData(compressionQuality: quality)
        }
        guard let final = data, final.count <= Constants.PhotoSearch.maxImageBytes else {
            return nil
        }
        return final
    }
}

extension PhotoSearchViewController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        if let error {
            Task { @MainActor in
                self.viewModel.state = .failed(.unknown(error.localizedDescription))
            }
            return
        }
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            Task { @MainActor in
                self.viewModel.state = .failed(.unknown(Constants.Strings.serverError))
            }
            return
        }
        Task { @MainActor in
            self.freezeFrame(image)
            guard let jpeg = self.compressForUpload(image) else {
                self.viewModel.state = .failed(.unknown(Constants.Strings.serverError))
                return
            }
            self.viewModel.process(imageJPEG: jpeg)
        }
    }
}

extension PhotoSearchViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
            return
        }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            Task { @MainActor in
                guard let self else { return }
                self.freezeFrame(image)
                guard let jpeg = self.compressForUpload(image) else {
                    self.viewModel.state = .failed(.unknown(Constants.Strings.serverError))
                    return
                }
                self.viewModel.process(imageJPEG: jpeg)
            }
        }
    }
}
