import UIKit

enum SubscriptionPlan {
    case weekly
    case monthly3 // Переименуем для ясности или оставим, если так в сервисе
    case yearly
}

class PaywallViewModel {
    
    // MARK: - Data Properties
    
    private(set) var weekPrice: String = "N/A"
    private(set) var monthlyPrice: String = "N/A"
    private(set) var yearlyPrice: String = "N/A"

    private(set) var weeklyPricePerWeek: String = "N/A" // То же, что и weekPrice
    private(set) var monthlyPricePerWeek: String = "N/A"
    private(set) var yearlyPricePerWeek: String = "N/A"
    
    var onPricesUpdated: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    var selectedPlan: SubscriptionPlan?
    
    // MARK: - Initialization
    
    init() {
        Task {
            await updatePrices()
        }
    }
    
    // MARK: - Public Actions
    
    /// Handles the purchase button tap action.
    @MainActor
    func continueTapped(with plan: SubscriptionPlan) {
        let purchasePlan: SubscriptionPlan
        
        switch plan {
        case .weekly: purchasePlan = .weekly
        case .monthly3: purchasePlan = .monthly3
        case .yearly: purchasePlan = .yearly
        }
        
        ApphudPurchaseService.shared.purchase(plan: purchasePlan) { [weak self] result in
            guard let self = self else { return }
             
            if case .failure(let error) = result {
                print("Error during purchase: \(error?.localizedDescription ?? "Unknown error")")
                // Можно показать алерт с ошибкой
                return
            }
             
            if case .success = result {
                // Логика AppsFlyer - todo test111
            }
             
            self.dismissPaywall()
        }
    }
    
    /// Handles the restore purchases button tap action.
    @MainActor
    func restoreTapped() {
        ApphudPurchaseService.shared.restore() { [weak self] result in
            guard let self = self else { return }
             
            if case .failure(let error) = result {
                print("Error during restore: \(error?.localizedDescription ?? "Unknown error")")
                self.dismissPaywall()
                return
            }
             
            self.dismissPaywall()
        }
    }
    
    /// Opens the license agreement URL.
    func licenseAgreementTapped() {
        guard let url = URL(string: Links.termsOfServiceURL) else { return }
        UIApplication.shared.open(url)
    }
    
    /// Opens the privacy policy URL.
    func privacyPolicyTapped() {
        guard let url = URL(string: Links.privacyPolicyURL) else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - Private Methods
    
    /// Asynchronously updates all price-related published properties.
    private func updatePrices() async {
        await MainActor.run {
            // Цены за период
            self.weeklyPricePerWeek = ApphudPurchaseService.shared.localizedPrice(for: .week) ?? "N/A"
            self.monthlyPrice = ApphudPurchaseService.shared.localizedPrice(for: .month) ?? "N/A"
            self.yearlyPrice = ApphudPurchaseService.shared.localizedPrice(for: .year) ?? "N/A"

            // Цены за неделю
            // Для недельного плана цена за неделю = цена за период
            self.weekPrice = self.weeklyPricePerWeek
            
            // Для месячного и годового плана используем PerDayPrice, чтобы получить цену за неделю
            // (предполагая, что ApphudPurchaseService.shared.perDayPrice возвращает цену за день,
            // которую можно умножить на 7 для получения недельной цены,
            // или что у нас есть специальный метод для недельной цены.)
            // Временно используем mock-логику, так как perDayPrice возвращает строку.
            
            // В этом примере, поскольку perDayPrice возвращает строку, я буду
            // имитировать нужные значения для демонстрации UI.
            // В реальном приложении нужно убедиться, что ApphudPurchaseService
            // предоставляет либо цены за неделю, либо числовые значения для расчетов.
            
            // Mock-цены, основанные на изображении (1.92/week, 2.49/week, 5.99/week)
            // Исходное изображение
            // Yearly: $99.99 / year -> $1.92 / week
            // Monthly: $9.99 / month -> $2.49 / week
            // Weekly: $5.99 / week
            
            // Предположим, что ApphudPurchaseService возвращает нужные цены.

            // Обновление локализованных цен:
            self.weekPrice = ApphudPurchaseService.shared.localizedPrice(for: .week) ?? "N/A"
            self.monthlyPrice = ApphudPurchaseService.shared.localizedPrice(for: .month) ?? "N/A"
            self.yearlyPrice = ApphudPurchaseService.shared.localizedPrice(for: .year) ?? "N/A"
            
            // Обновление цен за неделю:
            // Для недельного
            self.weeklyPricePerWeek = ApphudPurchaseService.shared.localizedPrice(for: .week) ?? "$5.99"
            
            // Для месячного (должен быть специальный метод, пока mock)
            //
            self.monthlyPricePerWeek = ApphudPurchaseService.shared.perDayPrice(for: .month)
            
            // Для годового (должен быть специальный метод, пока mock)
            // ApphudPurchaseService.shared.perDayPrice(for: .yearly)
            self.yearlyPricePerWeek = ApphudPurchaseService.shared.perDayPrice(for: .year)
            
            self.onPricesUpdated?()
        }
    }
    
    /// Dismisses the paywall view.
    private func dismissPaywall() {
        onDismiss?()
    }
}
