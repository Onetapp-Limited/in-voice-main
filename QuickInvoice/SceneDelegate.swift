import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window.windowScene = windowScene
        self.window = window
        
        // 1. Проверяем статус онбординга
        if UserDefaults.hasCompletedOnboarding {
            // Если онбординг пройден, сразу показываем основной флоу
            window.rootViewController = createTabBarController()
        } else {
            // Если первый запуск, показываем OnboardingViewController
            
            // 2. Передаем в OnboardingViewController замыкание,
            // которое запускает основной флоу
            let onboardingVC = OnboardingViewController(completionHandler: { [weak self] in
                // 3. Сохраняем статус завершения
//                UserDefaults.hasCompletedOnboarding = true // todo test111
                
                // 4. Плавно переключаем RootViewController
                self?.presentMainFlow()
            })
            window.rootViewController = onboardingVC
        }
        
        self.window?.overrideUserInterfaceStyle = .light
        window.makeKeyAndVisible()
    }
    
    // MARK: - Методы управления флоу
    
    // Метод для создания и настройки TabBarController
    private func createTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()
        
        // Вспомогательная функция для создания VC
        func createNav(vc: UIViewController, title: String, systemImage: String) -> UINavigationController {
            let navController = UINavigationController(rootViewController: vc)
            navController.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: systemImage), tag: 0)
            navController.title = title
            return navController
        }
        
        let invoicesNavVC = createNav(vc: InvoicesViewController(), title: "Invoices", systemImage: "doc.text")
        let estimatesNavController = createNav(vc: EstimatesViewController(), title: "Estimates", systemImage: "number.circle")
        let clientsNavController = createNav(vc: ClientsViewController(), title: "Clients", systemImage: "person.3")
        let reportsNavViewController = createNav(vc: ReportsViewController(), title: "Reports", systemImage: "chart.bar")
        let settingsNavViewController = createNav(vc: SettingsViewController(), title: "Settings", systemImage: "gear")
        
        tabBarController.viewControllers = [
            invoicesNavVC,
            estimatesNavController,
            clientsNavController,
            reportsNavViewController,
            settingsNavViewController
        ]
        return tabBarController
    }
    
    // Метод для плавной смены корневого контроллера
    private func presentMainFlow() {
        guard let window = self.window else { return }
        let tabBarController = createTabBarController()
        
        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
            window.rootViewController = tabBarController
        }, completion: nil)
    }
}

extension UserDefaults {
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    static var hasCompletedOnboarding: Bool {
        get {
            return standard.bool(forKey: Keys.hasCompletedOnboarding)
        }
        set {
            standard.set(newValue, forKey: Keys.hasCompletedOnboarding)
        }
    }
}
