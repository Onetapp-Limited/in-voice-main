//
//  AppDelegate.swift
//  QuickInvoice
//
//  Created by Alex Drewno on 7/29/20.
//  Copyright © 2020 Alex Drewno. All rights reserved.
//

import UIKit
import CoreData
import AppTrackingTransparency
import iAd // Для ASIdentifierManager
import AppsFlyerLib
import AdSupport
import ApphudSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private var uniqueUserID: String?

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 1. Инициализация сервиса покупок (если ApphudPurchaseService - это синглтон, как в вашем примере)
        _ = ApphudPurchaseService.shared
        
        // 2. Генерация/Получение Customer User ID
        let defaults = UserDefaults.standard
        let customerUserIDKey = "customer_user_id"
        let currentUserID: String
        
        if let storedUserID = defaults.string(forKey: customerUserIDKey) {
            currentUserID = storedUserID
        } else {
            currentUserID = UUID().uuidString
            defaults.set(currentUserID, forKey: customerUserIDKey)
        }
        self.uniqueUserID = currentUserID // Сохраняем ID, если нужно
        
        // 3. Настройка AppsFlyer (Должен быть настроен до Apphud)
        let afLib = AppsFlyerLib.shared()
        afLib.customerUserID = currentUserID // Синхронизируем Customer ID
        afLib.appleAppID = "6755155692"
        afLib.appsFlyerDevKey = "h5kHjF2iSYoT4ifCrrxtqW" // Замените на ваш ключ
        
        // 4. Запуск Apphud (ДОЛЖЕН БЫТЬ ЗАПУЩЕН НЕМЕДЛЕННО)
        Apphud.start(apiKey: "app_b3C4aRq1Xv2fTU5a9CYEU6aJAsLq46", userID: currentUserID) // Замените на ваш API ключ
        
        // 5. Запрос ATT (Асинхронно, с задержкой, как и было)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.requestTrackingAuthorization()
            
            // Вызов fetchProducts должен происходить после инициализации Apphud
            Task {
                await ApphudPurchaseService.shared.fetchProducts()
            }
        }
        
        // В UIKit вам также может потребоваться настроить `window` и корневой контроллер,
        // но для логики инициализации это необязательно.
        return true
    }
    
    // Вспомогательная функция для запроса ATT
    private func requestTrackingAuthorization() {
        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                
                let idfv = UIDevice.current.identifierForVendor?.uuidString ?? ""
                var idfa: String? = nil
                
                if status == .authorized {
                    // IDFA доступен только после .authorized
                    idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                }
                
                // 6. Передаем IDFA/IDFV в Apphud
                Apphud.setDeviceIdentifiers(idfa: idfa, idfv: idfv)
                
                // 7. Запуск AppsFlyer
                AppsFlyerLib.shared().start()
            }
        }
    }
    

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    lazy var persistentContainer: NSPersistentContainer = {

        let container = NSPersistentContainer(name: "QuickInvoiceModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {

                fatalError("Unresolved error, \((error as NSError).userInfo)")
            }
        })
        return container
    }()

}

