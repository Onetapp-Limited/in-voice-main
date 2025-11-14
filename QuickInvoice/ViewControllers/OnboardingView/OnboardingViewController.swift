import UIKit
import SnapKit

class OnboardingViewController: UIViewController {
    
    // Closure для запуска основного флоу, передается из SceneDelegate
    private let completionHandler: () -> Void
    
    private var currentPage: Int {
        get {
            // Безопасно получаем текущий индекс из pageControl
            return pageControl.currentPage
        }
        set {
            // Обновляем pageControl при программном перелистывании
            pageControl.currentPage = newValue
        }
    }
    
    // Массив экранов онбординга
    private lazy var pages: [UIViewController] = {
        return [
            OnboardingPageVC(imageName: "doc.text.fill.viewfinder", title: "Быстрые инвойсы", detail: "Создавайте профессиональные счета за считанные минуты."),
            OnboardingPageVC(imageName: "person.3.fill", title: "Учет клиентов", detail: "Вся база ваших клиентов всегда под рукой и актуальна."),
            OnboardingPageVC(imageName: "chart.bar.xaxis", title: "Аналитика и Отчеты", detail: "Отслеживайте доходы и расходы с помощью удобных отчетов."),
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
        return control
    }()
    
    private lazy var finishButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(didTapFinish), for: .touchUpInside)
        return button
    }()
    
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
        
        pageViewController.view.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-100)
        }
    }
    
    private func setupUI() {
        view.addSubview(pageControl)
        view.addSubview(finishButton)
        
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(finishButton.snp.top).offset(-10)
        }
        
        finishButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(30)
            make.height.equalTo(50)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
        }
    }
    
    // MARK: - Action
    
    @objc private func didTapFinish() {
        
        let nextIndex = currentPage + 1
        
        // 1. Проверяем, является ли текущая страница последней
        if nextIndex < pages.count {
            // 2. Если НЕ последняя страница, переходим к следующей
            
            let nextVC = pages[nextIndex]
            
            pageViewController.setViewControllers([nextVC], direction: .forward, animated: true) { [weak self] _ in
                // После анимации обновляем currentPage
                self?.currentPage = nextIndex
            }
            
        } else {
            // 3. Если это последняя страница, вызываем завершающий кложур
            completionHandler()
        }
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
