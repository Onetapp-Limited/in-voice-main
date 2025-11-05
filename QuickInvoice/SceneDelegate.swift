import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let tabBarController = UITabBarController()
        
        let invoicesVC = InvoicesViewController()
        let invoicesNavVC = UINavigationController(rootViewController: invoicesVC)
        invoicesNavVC.tabBarItem = UITabBarItem(
            title: "Invoices",
            image: UIImage(systemName: "doc.text"),
            tag: 0
        )
        invoicesNavVC.title = "Invoices"
        
        let estimatesViewController = EstimatesViewController()
        let estimatesNavController = UINavigationController(rootViewController: estimatesViewController)
        estimatesNavController.tabBarItem = UITabBarItem(
            title: "Estimates",
            image: UIImage(systemName: "number.circle"),
            tag: 0
        )
        estimatesNavController.title = "Estimates"
        
        let сlientsViewController = ClientsViewController()
        let сlientsNavController = UINavigationController(rootViewController: сlientsViewController)
        сlientsNavController.tabBarItem = UITabBarItem(
            title: "Clients",
            image: UIImage(systemName: "person.3"),
            tag: 0
        )
        сlientsNavController.title = "Clients"
        
        let reportsViewController = ReportsViewController()
        let reportsNavViewController = UINavigationController(rootViewController: reportsViewController)
        reportsNavViewController.tabBarItem = UITabBarItem(
            title: "Reports",
            image: UIImage(systemName: "chart.bar"),
            tag: 0
        )
        reportsNavViewController.title = "Reports"
        
        let settingsViewController = SettingsViewController()
        let settingsNavViewController = UINavigationController(rootViewController: settingsViewController)
        settingsNavViewController.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gear"),
            tag: 0
        )
        settingsNavViewController.title = "Settings"
        
        tabBarController.viewControllers = [
            invoicesNavVC,
            estimatesNavController,
            сlientsNavController,
            reportsNavViewController,
            settingsNavViewController
        ]
        
        // 7. Устанавливаем TabBarController как корневой контроллер
        let window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window.windowScene = windowScene
        window.rootViewController = tabBarController
        self.window = window
        self.window?.overrideUserInterfaceStyle = .light
        window.makeKeyAndVisible()
    }
}

