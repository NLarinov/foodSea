import UIKit
import Combine

final class OnboardingViewController: UIPageViewController {

    private let viewModel = OnboardingViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let slides: [(icon: String, title: String, description: String)] = [
        ("cart.fill",
         "Формируйте список покупок",
         "Добавляйте товары в корзину из каталога, через сканер штрихкода или голосовой ввод"),
        ("bolt.fill",
         "Экономьте автоматически",
         "Алгоритм найдёт оптимальное распределение покупок по магазинам для минимальной стоимости"),
        ("mic.and.signal.meter.fill",
         "Голос и сканер",
         "Просто назовите товары вслух или отсканируйте штрихкод — мы найдём лучшие цены")
    ]

    private lazy var pageControllers: [UIViewController] = slides.map { slide in
        let vc = UIViewController()
        let pageView = OnboardingPageView(
            title: slide.title,
            description: slide.description,
            iconName: slide.icon
        )
        pageView.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(pageView)
        pageView.pinToSuperview()
        return vc
    }

    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.currentPageIndicatorTintColor = .App.primary
        control.pageIndicatorTintColor = .App.secondaryLabel.withAlphaComponent(0.3)
        control.numberOfPages = Constants.Onboarding.slideCount
        control.isUserInteractionEnabled = false
        return control
    }()

    private let skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Пропустить", for: .normal)
        button.setTitleColor(.App.secondaryLabel, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .regular)
        return button
    }()

    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Далее", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: Constants.UI.titleFontSize, weight: .semibold)
        button.backgroundColor = .App.primary
        button.layer.cornerRadius = Constants.UI.cornerRadius
        return button
    }()

    var onComplete: (() -> Void)? {
        get { viewModel.onComplete }
        set { viewModel.onComplete = newValue }
    }

    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .App.background
        dataSource = self
        delegate = self

        setViewControllers([pageControllers[0]], direction: .forward, animated: false)
        setupControls()
        bindViewModel()
    }

    private func setupControls() {
        view.addSubview(skipButton)
        view.addSubview(pageControl)
        view.addSubview(nextButton)

        NSLayoutConstraint.activate([
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.UI.smallPadding),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.UI.standardPadding),
            skipButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.UI.minimumTapSize),

            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.UI.largePadding),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.UI.largePadding),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.UI.largePadding),
            nextButton.heightAnchor.constraint(equalToConstant: Constants.UI.buttonHeight),

            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -Constants.UI.standardPadding)
        ])

        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    private func bindViewModel() {
        viewModel.$currentPage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] page in
                self?.pageControl.currentPage = page
                let title = self?.viewModel.isLastPage == true ? "Начать" : "Далее"
                self?.nextButton.setTitle(title, for: .normal)
                self?.skipButton.isHidden = self?.viewModel.isLastPage == true
            }
            .store(in: &cancellables)
    }

    @objc private func skipTapped() {
        viewModel.skip()
    }

    @objc private func nextTapped() {
        if viewModel.isLastPage {
            viewModel.completeOnboarding()
        } else {
            let nextIndex = viewModel.currentPage + 1
            setViewControllers([pageControllers[nextIndex]], direction: .forward, animated: true)
            viewModel.currentPage = nextIndex
        }
    }
}

extension OnboardingViewController: UIPageViewControllerDataSource {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pageControllers.firstIndex(of: viewController), index > 0 else { return nil }
        return pageControllers[index - 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pageControllers.firstIndex(of: viewController),
              index < pageControllers.count - 1 else { return nil }
        return pageControllers[index + 1]
    }
}

extension OnboardingViewController: UIPageViewControllerDelegate {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let currentVC = viewControllers?.first,
              let index = pageControllers.firstIndex(of: currentVC) else { return }
        viewModel.currentPage = index
    }
}
