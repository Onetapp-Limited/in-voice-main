import Foundation

enum DiscountType: String, Codable, CaseIterable {
    case fixedAmount = "Fixed Amount"
    case percentage = "Percentage"
    
    var localized: String { return self.rawValue }
}

enum UnitType: String, Codable, CaseIterable {
    case hours = "Hours"
    case days = "Days"
    case item = "Item"
    
    var localized: String { return self.rawValue }
}

enum Currency: String, Codable, CaseIterable {
    case USD = "USD ($)" // United States Dollar
    case EUR = "EUR (€)" // Euro
    case GBP = "GBP (£)" // British Pound Sterling
    case JPY = "JPY (¥)" // Japanese Yen
    case AUD = "AUD (A$)" // Australian Dollar
    case CAD = "CAD (C$)" // Canadian Dollar
    case CHF = "CHF (CHF)" // Swiss Franc
    case CNY = "CNY (¥)" // Chinese Yuan
    case RUB = "RUB (₽)" // Russian Ruble
    case KZT = "KZT (₸)" // Kazakhstani Tenge

    // Свойство для получения только символа валюты
    var symbol: String {
        switch self {
        case .USD: return "$"
        case .EUR: return "€"
        case .GBP: return "£"
        case .JPY: return "¥"
        case .AUD: return "A$"
        case .CAD: return "C$"
        case .CHF: return "CHF"
        case .CNY: return "¥"
        case .RUB: return "₽"
        case .KZT: return "₸"
        }
    }

    // Свойство для получения кода валюты для форматирования
    var code: String {
        return self.rawValue.components(separatedBy: " ").first ?? "USD"
    }
}

enum InvoiceStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case readyToSend = "Ready To Send"
    case paid = "Paid"
    case pending = "Pending"
}

// MARK: - CompanyInfo Model
struct CompanyInfo: Codable {
    var name: String = "My Company"
    var street: String = ""
    var cityStateZip: String = ""
    var email: String = ""
    
    // Вспомогательная функция для получения данных компании из UserDefaults
    static func load() -> CompanyInfo? {
        if let savedData = UserDefaults.standard.data(forKey: "userCompanyInfo"),
           let decodedCompany = try? JSONDecoder().decode(CompanyInfo.self, from: savedData) {
            return decodedCompany
        }
        return nil // Возвращаем nil, если нет сохраненных данных
    }
    
    // Вспомогательная функция для сохранения данных компании в UserDefaults
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: "userCompanyInfo")
        }
    }
}

// --- InvoiceItem: ---

struct InvoiceItem: Codable {
    var id = UUID()
    var name: String?
    var description: String = ""
    var quantity: Double = 1.0
    var unitPrice: Double = 0.0
    
    // discountValue: Хранит процентное значение (0-100), если discountType = .percentage
    var discountValue: Double = 0.0
    var discountType: DiscountType = .fixedAmount
    var isTaxable: Bool = true
    var unitType: UnitType = .item
    
    var lineTotal: Double {
        let grossTotal = quantity * unitPrice
        return grossTotal
    }
}

// --- Енумы и Структура Client (без изменений) ---

enum ClientType: String, Codable, CaseIterable {
    case newClient = "New Client"
    case ongoing = "Ongoing"
    case recurrent = "Recurrent"
    
    var localized: String { return self.rawValue }
}

struct Client: Codable, Hashable {
    var id: UUID?
    var clientName: String?
    var email: String?
    var phoneNumber: String?
    var address: String?
    var idNumber: String?
    var faxNumber: String?
    var tags: [String] = []
    var clientType: ClientType = .newClient
}

// --- Invoice: ИСПРАВЛЕНИЕ taxTotal ---

struct Invoice: Codable {
    var id: UUID = UUID()
    var invoiceTitle: String? = ""
    var client: Client?
    var items: [InvoiceItem] = []
    // taxRate: Хранит процентное значение (0-100)
    var taxRate: Double = 0
    var discount: Double = 0
    var discountType: DiscountType = .fixedAmount
    
    var invoiceDate: Date = Date()
    var dueDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
    var creationDate: Date = Date()
    
    var status: InvoiceStatus = .draft
    var currency: Currency = .USD
    
    var senderCompany: CompanyInfo?
    
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
