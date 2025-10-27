import Foundation

// MARK: - Discount Type Enum
enum DiscountType: String, Codable, CaseIterable {
    case fixedAmount = "Fixed Amount"
    case percentage = "Percentage"
    
    var localized: String {
        return self.rawValue
    }
}

// MARK: - Unit Type Enum
enum UnitType: String, Codable, CaseIterable {
    case hours = "Hours"
    case days = "Days"
    case item = "Item" // Добавляем 'Item' как стандартный вариант
    
    var localized: String {
        return self.rawValue
    }
}

// MARK: - Invoice Item Model (Updated)

struct InvoiceItem: Codable {
    var id = UUID()
    var name: String? // Новое поле для "Name"
    var description: String = ""
    var quantity: Double = 1.0 // Устанавливаем 1.0 по умолчанию
    var unitPrice: Double = 0.0
    
    var discountValue: Double = 0.0
    var discountType: DiscountType = .percentage
    var isTaxable: Bool = true // Тогл Taxable
    var unitType: UnitType = .item // Тип Days or Hours
    
    var lineTotal: Double {
        let grossTotal = quantity * unitPrice
        var netTotal = grossTotal
        
        // Применяем скидку
        if discountValue > 0 {
            switch discountType {
            case .percentage:
                netTotal -= grossTotal * (discountValue / 100.0)
            case .fixedAmount:
                netTotal -= discountValue
            }
        }
        return max(0, netTotal) // Итоговая сумма не может быть меньше 0
    }
}

enum ClientType: String, Codable, CaseIterable {
    case newClient = "New Client"
    case ongoing = "Ongoing"
    case recurrent = "Recurrent"
    
    var localized: String {
        return self.rawValue
    }
}

// MARK: - Client Model

struct Client: Codable {
    var id: UUID?
    var clientName: String? // Name (Required)
    var email: String?
    var phoneNumber: String?
    var address: String?
    var idNumber: String? // ID Number
    var faxNumber: String?
    var tags: [String] = []
    var clientType: ClientType = .newClient // New Client, Ongoing, Recurrent
}

// MARK: - Invoice Model

struct Invoice: Codable {
    var id: UUID = UUID()
    var invoiceTitle: String? = ""
    var client: Client?
    var items: [InvoiceItem] = []
    var taxRate: Double = 0.0
    var discount: Double = 0.0
    var invoiceDate: Date = Date()
    var dueDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
    var creationDate: Date = Date()
    var status: String = "Paid"
}
