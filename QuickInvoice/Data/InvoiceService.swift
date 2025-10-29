import Foundation
import RealmSwift

// MARK: - 1. Realm Object Definitions (Обновлено)

// Client Object (Без изменений, т.к. его структура уже была обновлена)
class ClientObject: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var clientName: String?
    @Persisted var email: String?
    @Persisted var phoneNumber: String?
    @Persisted var address: String?
    @Persisted var idNumber: String?
    @Persisted var faxNumber: String?
    @Persisted var tags = RealmSwift.List<String>()
    @Persisted var clientTypeRaw: String = ClientType.newClient.rawValue

    // Конвертер из Swift структуры в Realm Object (Без изменений)
    convenience init(client: Client) {
        self.init()
        self.id = client.id?.uuidString ?? UUID().uuidString
        self.clientName = client.clientName
        self.email = client.email
        self.phoneNumber = client.phoneNumber
        self.address = client.address
        self.idNumber = client.idNumber
        self.faxNumber = client.faxNumber
        self.tags.append(objectsIn: client.tags)
        self.clientTypeRaw = client.clientType.rawValue
    }

    // Конвертер из Realm Object в Swift структуру (Без изменений)
    var toStruct: Client {
        let type = ClientType(rawValue: clientTypeRaw) ?? .newClient
        return Client(
            id: UUID(uuidString: id),
            clientName: clientName,
            email: email,
            phoneNumber: phoneNumber,
            address: address,
            idNumber: idNumber,
            faxNumber: faxNumber,
            tags: Array(tags),
            clientType: type
        )
    }
}

// Invoice Item Object (EmbeddedObject, Без изменений)
class InvoiceItemObject: EmbeddedObject {
    @Persisted var id: String = UUID().uuidString
    @Persisted var name: String?
    @Persisted var itemDescription: String = "" // Используем другое имя, чтобы избежать конфликта с 'description'
    @Persisted var quantity: Double = 1.0
    @Persisted var unitPrice: Double = 0.0

    @Persisted var discountValue: Double = 0.0
    @Persisted var discountTypeRaw: String = DiscountType.fixedAmount.rawValue
    @Persisted var isTaxable: Bool = true
    @Persisted var unitTypeRaw: String = UnitType.item.rawValue

    // Конвертер из Swift структуры в Realm Object (Без изменений)
    convenience init(item: InvoiceItem) {
        self.init()
        self.id = item.id.uuidString
        self.name = item.name
        self.itemDescription = item.description
        self.quantity = item.quantity
        self.unitPrice = item.unitPrice
        
        self.discountValue = item.discountValue
        self.discountTypeRaw = item.discountType.rawValue
        self.isTaxable = item.isTaxable
        self.unitTypeRaw = item.unitType.rawValue
    }

    // Конвертер из Realm Object в Swift структуру (Без изменений)
    var toStruct: InvoiceItem {
        let discountType = DiscountType(rawValue: discountTypeRaw) ?? .fixedAmount
        let unitType = UnitType(rawValue: unitTypeRaw) ?? .item
        
        return InvoiceItem(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            description: itemDescription,
            quantity: quantity,
            unitPrice: unitPrice,
            discountValue: discountValue,
            discountType: discountType,
            isTaxable: isTaxable,
            unitType: unitType
        )
    }
}

class InvoiceObject: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var invoiceTitle: String?
    @Persisted var client: ClientObject?
    @Persisted var items = RealmSwift.List<InvoiceItemObject>()
    @Persisted var taxRate: Double = 0.0
    @Persisted var discount: Double = 0.0
    
    // ⭐ НОВОЕ ПОЛЕ: Тип скидки для всего инвойса
    @Persisted var discountTypeRaw: String = DiscountType.fixedAmount.rawValue
    
    @Persisted var invoiceDate: Date = Date()
    @Persisted var dueDate: Date = Date()
    @Persisted var creationDate: Date = Date()
    
    @Persisted var statusRaw: String = InvoiceStatus.draft.rawValue
    @Persisted var currencyRaw: String = Currency.USD.rawValue
    
    @Persisted var totalAmount: String = ""

    // Конвертер из Swift структуры в Realm Object (ОБНОВЛЕН)
    convenience init(invoice: Invoice, clientObject: ClientObject?) {
        self.init()
        self.id = invoice.id.uuidString
        self.invoiceTitle = invoice.invoiceTitle
        
        self.client = clientObject
        
        self.items.append(objectsIn: invoice.items.map { InvoiceItemObject(item: $0) })
        self.taxRate = invoice.taxRate
        self.discount = invoice.discount
        
        // ⭐ НОВОЕ ПОЛЕ: Сохранение discountType
        self.discountTypeRaw = invoice.discountType.rawValue
        
        self.invoiceDate = invoice.invoiceDate
        self.dueDate = invoice.dueDate
        self.creationDate = invoice.creationDate
        
        self.statusRaw = invoice.status.rawValue
        self.currencyRaw = invoice.currency.rawValue
        
        self.totalAmount = invoice.totalAmount
    }

    // Конвертер из Realm Object в Swift структуру (ОБНОВЛЕН)
    var toStruct: Invoice {
        let status = InvoiceStatus(rawValue: statusRaw) ?? .draft
        let currency = Currency(rawValue: currencyRaw) ?? .USD
        
        // ⭐ НОВОЕ ПОЛЕ: Конвертация discountType
        let discountType = DiscountType(rawValue: discountTypeRaw) ?? .fixedAmount

        return Invoice(
            id: UUID(uuidString: id) ?? UUID(),
            invoiceTitle: invoiceTitle,
            client: client?.toStruct,
            items: Array(items.map { $0.toStruct }),
            taxRate: taxRate,
            discount: discount,
            discountType: discountType, // ⭐ Использование сконвертированного DiscountType
            invoiceDate: invoiceDate,
            dueDate: dueDate,
            creationDate: creationDate,
            status: status,
            currency: currency,
            totalAmount: totalAmount
        )
    }
}

// MARK: - 2. Invoice Service (Обновлено)

protocol InvoiceServiceProtocol {
    func save(invoice: Invoice) throws
    func getAllInvoices() -> [Invoice]
    func getInvoice(id: UUID) -> Invoice?
    func deleteInvoice(id: UUID) throws
    func deleteAllInvoices() throws
    func updateInvoice(_ newInvoice: Invoice) throws // Добавим в протокол для полноты
}

class InvoiceService: InvoiceServiceProtocol {
    private let realm: Realm

    init() throws {
        // ⚠️ УВЕЛИЧИВАЕМ ВЕРСИЮ СХЕМЫ
        let currentSchemaVersion: UInt64 = 4

        let config = Realm.Configuration(
            schemaVersion: currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                
                //  Миграция с версии < 3
                
                if oldSchemaVersion < 4 {
                    // Миграция с версии 3 до версии 4: Добавлено поле discountTypeRaw в InvoiceObject.
                    migration.enumerateObjects(ofType: InvoiceObject.className()) { oldObject, newObject in
                        // ⭐ НОВОЕ ПОЛЕ: discountTypeRaw
                        // Устанавливаем значение по умолчанию, чтобы старые счета не крашились.
                        // Если вы используете RealmSwift > 10.25.0 и это *новое* поле,
                        // Realm установит значение по умолчанию, указанное в @Persisted (DiscountType.fixedAmount.rawValue).
                        // Вручную это можно сделать так:
                        newObject!["discountTypeRaw"] = DiscountType.fixedAmount.rawValue
                    }
                }
                
                print("Realm migration finished: \(oldSchemaVersion) -> \(currentSchemaVersion)")
            }
        )
        Realm.Configuration.defaultConfiguration = config
        
        self.realm = try Realm()
    }

    // MARK: - CRUD Operations

    /// Добавляет новый счет или обновляет существующий.
    func save(invoice: Invoice) throws {
        var clientObject: ClientObject? = nil

        // ШАГ 1: Сохраняем/обновляем клиента перед сохранением счета.
        if let clientStruct = invoice.client {
            // Создаем объект клиента.
            clientObject = ClientObject(client: clientStruct)

            try realm.write {
                // Сохраняем клиента. .modified гарантирует, что существующий клиент будет обновлен.
                realm.add(clientObject!, update: .modified)
            }
        }

        // ШАГ 2: Создаем Realm Object из Swift структуры, передавая ему сохраненного клиента.
        // Используется ОБНОВЛЕННЫЙ InvoiceObject(invoice:clientObject:)
        let invoiceObject = InvoiceObject(invoice: invoice, clientObject: clientObject)

        try realm.write {
            // Сохраняем счет-фактуру.
            realm.add(invoiceObject, update: .modified)
        }
    }

    /// Получает все счета.
    func getAllInvoices() -> [Invoice] {
        let results = realm.objects(InvoiceObject.self)
            .sorted(byKeyPath: "creationDate", ascending: false)

        // Маппинг Realm Results в массив Swift структур
        // Используется ОБНОВЛЕННЫЙ InvoiceObject.toStruct
        return results.map { $0.toStruct }
    }

    /// Получает счет по его уникальному ID.
    func getInvoice(id: UUID) -> Invoice? {
        let object = realm.object(ofType: InvoiceObject.self, forPrimaryKey: id.uuidString)
        // Используется ОБНОВЛЕННЫЙ InvoiceObject.toStruct
        return object?.toStruct
    }

    /// Удаляет счет по его ID.
    func deleteInvoice(id: UUID) throws {
        guard let objectToDelete = realm.object(ofType: InvoiceObject.self, forPrimaryKey: id.uuidString) else {
            return
        }

        try realm.write {
            realm.delete(objectToDelete)
        }
    }

    /// Удаляет все счета из базы данных.
    func deleteAllInvoices() throws {
        let invoiceObjectsToDelete = realm.objects(InvoiceObject.self)
        let clientObjectsToDelete = realm.objects(ClientObject.self)

        try realm.write {
            realm.delete(invoiceObjectsToDelete)
            realm.delete(clientObjectsToDelete)
        }
    }
    
    // Метод для обновления (также ОБНОВЛЕН, чтобы учесть новые поля)
    func updateInvoice(_ newInvoice: Invoice) throws {
        guard let existingInvoice = realm.object(ofType: InvoiceObject.self, forPrimaryKey: newInvoice.id.uuidString) else {
            print("❌ Invoice not found with id: \(newInvoice.id)")
            return
        }
        
        try realm.write {
            // Обновляем простые поля
            existingInvoice.invoiceTitle = newInvoice.invoiceTitle
            existingInvoice.taxRate = newInvoice.taxRate
            existingInvoice.discount = newInvoice.discount
            
            // ⭐ НОВОЕ ПОЛЕ: Обновление типа скидки
            existingInvoice.discountTypeRaw = newInvoice.discountType.rawValue
            
            existingInvoice.invoiceDate = newInvoice.invoiceDate
            existingInvoice.dueDate = newInvoice.dueDate
            
            // 💡 НОВЫЕ ПОЛЯ: Обновление статуса и валюты
            existingInvoice.statusRaw = newInvoice.status.rawValue
            existingInvoice.currencyRaw = newInvoice.currency.rawValue
            existingInvoice.totalAmount = newInvoice.totalAmount
            
            // Обновляем клиента (если передан)
            if let clientStruct = newInvoice.client {
                let clientObject = ClientObject(client: clientStruct)
                // Важно: встраиваемые объекты (EmbeddedObject) не нужно добавлять/обновлять отдельно,
                // они автоматически управляются родительским объектом. ClientObject - не встраиваемый,
                // поэтому его обновляем отдельно.
                realm.add(clientObject, update: .modified)
                existingInvoice.client = clientObject
            } else {
                existingInvoice.client = nil // Если клиент удален
            }
            
            // Обновляем items — сначала очищаем старые, потом добавляем новые
            existingInvoice.items.removeAll()
            let newItemObjects = newInvoice.items.map { InvoiceItemObject(item: $0) }
            existingInvoice.items.append(objectsIn: newItemObjects)
        }
        
        print("✅ Invoice updated: \(newInvoice.id)")
    }
}
