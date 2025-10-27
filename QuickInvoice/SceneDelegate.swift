import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // 1. Создаем главный контейнер - UITabBarController
        let tabBarController = UITabBarController()
        
        // 2. Создаем первый ViewController (HomeViewController)
        let homeVC = HomeViewController()
        
        // 3. Создаем NavigationController (HomeViewControllerNC)
        // В него мы встраиваем HomeViewController
        let homeNavController = UINavigationController(rootViewController: homeVC)
        
        // 4. Настраиваем иконку и заголовок для первой вкладки (Home)
        homeNavController.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"), // Используем SF Symbols
            tag: 0
        )
        // Дополнительно: можно задать заголовок для Navigation Bar
        homeVC.title = "Main Dashboard"
        
        // 5. Создаем остальные 4 заглушки (Dummy View Controllers)
        let dummyVC2 = self.createDummyViewController(
            title: "Clients",
            systemImageName: "person.3"
        )
        let dummyVC3 = self.createDummyViewController(
            title: "Items",
            systemImageName: "tag"
        )
        let dummyVC4 = self.createDummyViewController(
            title: "Invoices",
            systemImageName: "doc.text"
        )
        let dummyVC5 = self.createDummyViewController(
            title: "Settings",
            systemImageName: "gear"
        )
        
        // 6. Собираем массив всех View Controllers и устанавливаем его в TabBarController
        tabBarController.viewControllers = [
            homeNavController, // Это HomeViewControllerNC
            dummyVC2,
            dummyVC3,
            dummyVC4,
            dummyVC5
        ]
        
        // 7. Устанавливаем TabBarController как корневой контроллер
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = tabBarController
        self.window = window
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

