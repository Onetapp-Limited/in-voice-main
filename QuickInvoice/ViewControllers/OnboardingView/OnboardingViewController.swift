import UIKit
import SnapKit

class OnboardingViewController: UIViewController {
    
    private let completionHandler: () -> Void
    
    private var currentPage: Int {
        get {
            return pageControl.currentPage
        }
        set {
            pageControl.currentPage = newValue
        }
    }
    
    private lazy var pages: [UIViewController] = {
        return [
            OnboardingPageVC(imageName: "onbord1", title: "Create & Send Invoices in Seconds", detail: "Professional invoices in a couple of taps — no hassle, no templates needed", highlightedText: "in Seconds"),
            OnboardingPageVC(imageName: "onbord2", title: "Track Income,\nExpenses & Balance", detail: "All your financial stats in one place. Clear and automatic", highlightedText: "Track Income,"),
            OnboardingPageVC(imageName: "onbord3", title: "Manage Clients &\nGrow Your Business", detail: "Store clients, create estimates, track payments — work like a pro", highlightedText: "Grow Your Business"),
        ]
    }()
    
    private lazy var pageViewController: UIPageViewController = {
        let pvc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pvc.dataSource = self
        pvc.delegate = self
        return pvc
    }()
    
    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.numberOfPages = pages.count
        control.currentPageIndicatorTintColor = .systemBlue
        control.pageIndicatorTintColor = .lightGray
        control.isHidden = true
        return control
    }()
    
    private lazy var finishButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 30
        button.addTarget(self, action: #selector(didTapFinish), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Дополнительные кнопки
    
    private lazy var privacyPolicyButton: UIButton = {
        return createTextButton(title: "Privacy Policy", action: #selector(didTapPrivacyPolicy))
    }()
    
    private lazy var restoreButton: UIButton = {
        return createTextButton(title: "Restore", action: #selector(didTapRestore))
    }()
    
    private lazy var termsOfUseButton: UIButton = {
        return createTextButton(title: "Terms of Use", action: #selector(didTapTermsOfUse))
    }()
    
    private lazy var legalButtonsStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [privacyPolicyButton, restoreButton, termsOfUseButton])
        stack.axis = .horizontal
        stack.spacing = 15 // Отступ между кнопками
        stack.distribution = .equalSpacing // Равномерно распределяем пространство
        return stack
    }()
    
    private func createTextButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        button.setTitleColor(.darkGray, for: .normal) // Цвет текста
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    // MARK: - Инициализация
    
    init(completionHandler: @escaping () -> Void) {
        self.completionHandler = completionHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Жизненный цикл

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupPageViewController()
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupPageViewController() {
        if let firstVC = pages.first {
            pageViewController.setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
    }
    
    private func setupUI() {
        view.addSubview(pageControl)
        view.addSubview(finishButton)
        view.addSubview(legalButtonsStackView) // Добавляем стек с новыми кнопками
        
        // Констрейнты для кнопки Continue (finishButton)
        finishButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.height.equalTo(60)
            // Привязываем ее выше стека с доп. кнопками
            make.bottom.equalTo(legalButtonsStackView.snp.top).offset(-15)
        }

        // Констрейнты для стека с юридическими кнопками (внизу)
        legalButtonsStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview() // Центрируем стек
            make.leading.trailing.equalToSuperview().inset(30)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-5) // Отступ от нижнего края safe area
        }
        
        // Констрейнты для PageControl
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(finishButton.snp.top).offset(-20)
        }
        
        // Констрейнты для PageViewController
        pageViewController.view.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(finishButton.snp.top).inset(30)
        }
    }
    
    // MARK: - Action
    
    @objc private func didTapFinish() {
        let nextIndex = currentPage + 1
        
        if nextIndex < pages.count {
            let nextVC = pages[nextIndex]
            pageViewController.setViewControllers([nextVC], direction: .forward, animated: true) { [weak self] _ in
                self?.currentPage = nextIndex
            }
        } else {
            completionHandler()
        }
    }
    
    // MARK: - Заглушки для обработчиков новых кнопок
    
    @objc private func didTapPrivacyPolicy() {
        openExternalURL(string: Links.privacyPolicyURL)
    }
    
    @objc private func didTapRestore() {
        print("Нажата кнопка: Restore Purchases")
        // todo test111
    }
    
    @objc private func didTapTermsOfUse() {
        openExternalURL(string: Links.termsOfServiceURL)
    }
    
    private func openExternalURL(string: String) {
        guard let url = URL(string: string) else {
            print("SettingsViewController: Invalid URL string: \(string)")
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

// MARK: - UIPageViewControllerDataSource
extension OnboardingViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = pages.firstIndex(of: viewController) else { return nil }
        let previousIndex = currentIndex - 1
        return previousIndex < 0 ? nil : pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = pages.firstIndex(of: viewController) else { return nil }
        let nextIndex = currentIndex + 1
        return nextIndex >= pages.count ? nil : pages[nextIndex]
    }
}

// MARK: - UIPageViewControllerDelegate
extension OnboardingViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard
            completed,
            let currentVC = pageViewController.viewControllers?.first,
            let currentIndex = pages.firstIndex(of: currentVC)
        else { return }
        
        pageControl.currentPage = currentIndex
    }
}
