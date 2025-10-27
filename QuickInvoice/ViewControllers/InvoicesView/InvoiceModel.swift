import UIKit

struct InvoiceItem: Codable {
    var id = UUID()
    var description: String = ""
    var quantity: Double = 0.0
    var unitPrice: Double = 0.0
    
    var lineTotal: Double {
        return quantity * unitPrice
    }
}

struct Client {
    var id: UUID?
    var clientName: String?
    var address: String?
}

struct Invoice {
    var id: UUID = UUID()
    var invoiceTitle: String? = "Invoice Title"
    var client: Client?
    var items: [InvoiceItem] = []
    var taxRate: Double = 0.0 // Stored as 0.XX (e.g., 0.10 for 10%)
    var discount: Double = 0.0 // Flat amount discount
    var invoiceDate: Date = Date()
    var dueDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
    var creationDate: Date = Date() // Добавлено для сортировки в Realm
    var status: String = "Paid" // Added status for detail view context
}
