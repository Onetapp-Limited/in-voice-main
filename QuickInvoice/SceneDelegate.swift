import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window.windowScene = windowScene
        self.window = window
        
        let isFirstLaunch = true // !UserDefaults.hasCompletedOnboarding // test111
        
        if UserDefaults.hasCompletedOnboarding {
            window.rootViewController = createTabBarController()
        } else {
            UserDefaults.hasCompletedOnboarding = true
            let onboardingVC = OnboardingViewController(completionHandler: { [weak self] in
                self?.presentMainFlow(isFirstLaunch: isFirstLaunch)
            })
            window.rootViewController = onboardingVC
        }
        
        self.window?.overrideUserInterfaceStyle = .light
        window.makeKeyAndVisible()
    }
        
    private func createTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()
        
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
    
    private func presentMainFlow(isFirstLaunch: Bool = false) {
        guard let window = self.window else { return }
        
        let tabBarController = createTabBarController()
        window.rootViewController = tabBarController
        
        if isFirstLaunch {
            let paywallVC = PaywallViewController()
            paywallVC.topOffset = 30
            paywallVC.modalPresentationStyle = .fullScreen
            tabBarController.present(paywallVC, animated: true)
        }
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
