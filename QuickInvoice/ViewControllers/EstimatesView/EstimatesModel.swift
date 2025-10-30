import UIKit

struct Estimate: Codable {
    var id: UUID = UUID()
    var estimateTitle: String? = ""
    var client: Client?
    var items: [InvoiceItem] = []
    // taxRate: Хранит процентное значение (0-100)
    var taxRate: Double = 0
    var discount: Double = 0
    var discountType: DiscountType = .fixedAmount
    
    var creationDate: Date = Date()
    
    var status: InvoiceStatus = .draft
    var currency: Currency = .USD
    
    var totalAmount: String = ""

    var subtotal: Double {
        return items.reduce(0) { $0 + $1.lineTotal }
    }

    var taxTotal: Double {
        let taxableSubtotal = items.filter { $0.isTaxable }.reduce(0) { $0 + $1.lineTotal }
        let rateAsDecimal = taxRate / 100.0
        return taxableSubtotal * rateAsDecimal
    }
    
    var discountValue: Double {
        let taxableTotal = subtotal + taxTotal // Обычно скидка применяется к сумме до или после налога. В данном случае, судя по старому grandTotal, применяется после налога.
        switch discountType {
        case .fixedAmount:
            return min(discount, taxableTotal) // Не даем скидке превысить общую сумму
        case .percentage:
            // Скидка хранится как процент (0-100), применяем к общей сумме (Subtotal + TaxTotal)
            let rateAsDecimal = discount / 100.0
            return taxableTotal * rateAsDecimal
        }
    }

    var grandTotal: Double {
        let total = subtotal + taxTotal
        return max(0, total - discountValue)
    }

    var currencySymbol: String { return currency.symbol }
}
