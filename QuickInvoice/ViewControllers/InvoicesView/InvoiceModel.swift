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

struct InvoiceItem: Codable {
    var id = UUID()
    var name: String?
    var description: String = ""
    var quantity: Double = 1.0
    var unitPrice: Double = 0.0
    
    var discountValue: Double = 0.0
    var discountType: DiscountType = .percentage
    var isTaxable: Bool = true
    var unitType: UnitType = .item
    
    var lineTotal: Double {
        let grossTotal = quantity * unitPrice
        var netTotal = grossTotal
        
        if discountValue > 0 {
            switch discountType {
            case .percentage:
                netTotal -= grossTotal * (discountValue / 100.0)
            case .fixedAmount:
                netTotal -= discountValue
            }
        }
        return max(0, netTotal)
    }
}

enum ClientType: String, Codable, CaseIterable {
    case newClient = "New Client"
    case ongoing = "Ongoing"
    case recurrent = "Recurrent"
    
    var localized: String { return self.rawValue }
}

struct Client: Codable {
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

struct Invoice: Codable {
    var id: UUID = UUID()
    var invoiceTitle: String? = ""
    var client: Client?
    var items: [InvoiceItem] = []
    var taxRate: Double = 0 // Предполагаемая ставка налога
    var discount: Double = 0 // Общая скидка на инвойс
    var invoiceDate: Date = Date()
    var dueDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
    var creationDate: Date = Date()
    var status: String = "Draft"
    var totalAmount: String = "" // Строковое поле, которое мы будем вычислять
    
    var subtotal: Double {
        return items.reduce(0) { $0 + $1.lineTotal }
    }
    
    var taxTotal: Double {
        let taxableSubtotal = items.filter { $0.isTaxable }.reduce(0) { $0 + $1.lineTotal }
        return taxableSubtotal * (taxRate / 100.0)
    }
    
    var grandTotal: Double {
        let total = subtotal + taxTotal
        return max(0, total - discount)
    }
    
    var currencySymbol: String { return "$" } // Предполагаем $ для примера
}
