import UIKit

enum SubscriptionPlan {
    case weekly
    case monthly3
    case yearly
}

class PaywallViewModel {
    
    // MARK: - Data Properties
    
    private(set) var weekPrice: String = "N/A"
    private(set) var weekPricePerDay: String = "N/A"
    
    var onPricesUpdated: (() -> Void)?
    var onDismiss: (() -> Void)?

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
        ApphudPurchaseService.shared.purchase(plan: plan) { [weak self] result in
            guard let self = self else { return }
            
            if case .failure(let error) = result {
                print("Error during purchase: \(error?.localizedDescription ?? "Unknown error")")
                // Можно показать алерт с ошибкой
                return
            }
            
            if case .success = result {
                // Логика AppsFlyer
                // todo test111
//                AppsFlyerLib.shared().logEvent("af_purchase", withValues: [
//                    AFEventParamRevenue: self.weekPrice,
//                    AFEventParamCurrency: ApphudPurchaseService.shared.currency,
//                    AFEventParamContentId: PurchaseServiceProduct.week.rawValue
//                ])
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
                // Можно показать алерт с ошибкой, но диссмис, как в оригинале
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
            self.weekPrice = ApphudPurchaseService.shared.localizedPrice(for: .week) ?? "N/A"
            self.weekPricePerDay = ApphudPurchaseService.shared.perDayPrice(for: .week)
            self.onPricesUpdated?() // Уведомляем контроллер об обновлении
        }
    }
    
    /// Dismisses the paywall view.
    private func dismissPaywall() {
        onDismiss?()
    }
}
