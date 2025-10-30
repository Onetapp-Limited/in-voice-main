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
        
        let dummyVC2 = self.createDummyViewController(
            title: "Clients",
            systemImageName: "person.3"
        )
        let dummyVC3 = self.createDummyViewController(
            title: "Items",
            systemImageName: "tag"
        )
        
        let dummyVC5 = self.createDummyViewController(
            title: "Settings",
            systemImageName: "gear"
        )
        
        tabBarController.viewControllers = [
            invoicesNavVC,
            estimatesNavController,
            dummyVC2,
            dummyVC3,
            dummyVC5
        ]
        
        // 7. Устанавливаем TabBarController как корневой контроллер
        let window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window.windowScene = windowScene
        window.rootViewController = tabBarController
        self.window = window
        self.window?.overrideUserInterfaceStyle = .light
        window.makeKeyAndVisible()
    }
    
    // Вспомогательная функция для создания заглушек
    private func createDummyViewController(title: String, systemImageName: String) -> UIViewController {
        let vc = UIViewController()
        
        // Создаем Navigation Controller для каждой заглушки
        let navController = UINavigationController(rootViewController: vc)
        
        // Настраиваем Tab Bar Item
        navController.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: systemImageName),
            tag: 0
        )
        // Настраиваем заголовок
        vc.title = title
        
        // Для наглядности
        vc.view.backgroundColor = .systemBackground
        
        return navController
    }
}

