import Foundation
import RealmSwift

// MARK: - 1. Realm Object Definitions (Обновлено)

// Для хранения строковых enum'ов (DiscountType, UnitType, ClientType)
// в Realm мы будем использовать их rawValue (String).
// Realm автоматически сохраняет @Persisted String.

// Client Object (Обновлено)
class ClientObject: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var clientName: String?
    @Persisted var email: String? // Новое поле
    @Persisted var phoneNumber: String? // Новое поле
    @Persisted var address: String?
    @Persisted var idNumber: String? // Новое поле
    @Persisted var faxNumber: String? // Новое поле
    @Persisted var tags = RealmSwift.List<String>() // Новое поле (List для массива String)
    @Persisted var clientTypeRaw: String = ClientType.newClient.rawValue // Новое поле (храним rawValue)

    // Конвертер из Swift структуры в Realm Object
    convenience init(client: Client) {
        self.init()
        self.id = client.id?.uuidString ?? UUID().uuidString
        self.clientName = client.clientName
        self.email = client.email
        self.phoneNumber = client.phoneNumber
        self.address = client.address
        self.idNumber = client.idNumber
        self.faxNumber = client.faxNumber
        // Маппинг массива String в Realm List<String>
        self.tags.append(objectsIn: client.tags)
        self.clientTypeRaw = client.clientType.rawValue
    }

    // Конвертер из Realm Object в Swift структуру
    var toStruct: Client {
        // Безопасное приведение rawValue к enum
        let type = ClientType(rawValue: clientTypeRaw) ?? .newClient
        return Client(
            id: UUID(uuidString: id),
            clientName: clientName,
            email: email,
            phoneNumber: phoneNumber,
            address: address,
            idNumber: idNumber,
            faxNumber: faxNumber,
            tags: Array(tags), // Конвертируем Realm List обратно в Swift Array
            clientType: type
        )
    }
}

// Invoice Item Object (EmbeddedObject, Обновлено)
class InvoiceItemObject: EmbeddedObject {
    @Persisted var id: String = UUID().uuidString
    @Persisted var name: String? // Новое поле
    @Persisted var itemDescription: String = "" // Используем другое имя, чтобы избежать конфликта с 'description'
    @Persisted var quantity: Double = 1.0
    @Persisted var unitPrice: Double = 0.0

    @Persisted var discountValue: Double = 0.0 // Новое поле
    @Persisted var discountTypeRaw: String = DiscountType.percentage.rawValue // Новое поле (храним rawValue)
    @Persisted var isTaxable: Bool = true // Новое поле
    @Persisted var unitTypeRaw: String = UnitType.item.rawValue // Новое поле (храним rawValue)

    // Конвертер из Swift структуры в Realm Object
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

    // Конвертер из Realm Object в Swift структуру
    var toStruct: InvoiceItem {
        // Безопасное приведение rawValue к enum
        let discountType = DiscountType(rawValue: discountTypeRaw) ?? .percentage
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

// Invoice Object (Главный объект для хранения, без изменений структуры)
class InvoiceObject: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var invoiceTitle: String?
    @Persisted var client: ClientObject?
    @Persisted var items = RealmSwift.List<InvoiceItemObject>() // Список позиций
    @Persisted var taxRate: Double = 0.0
    @Persisted var discount: Double = 0.0
    @Persisted var invoiceDate: Date = Date()
    @Persisted var dueDate: Date = Date()
    @Persisted var creationDate: Date = Date() // Дата создания для сортировки
    @Persisted var status: String = "Paid"

    // Конвертер из Swift структуры в Realm Object (обновлен для использования обновленного InvoiceItemObject)
    convenience init(invoice: Invoice, clientObject: ClientObject?) {
        self.init()
        self.id = invoice.id.uuidString
        self.invoiceTitle = invoice.invoiceTitle
        
        self.client = clientObject // Клиент передается уже сохраненным объектом
        
        // Маппинг массива структур в Realm List объектов (используется обновленный InvoiceItemObject)
        self.items.append(objectsIn: invoice.items.map { InvoiceItemObject(item: $0) })
        self.taxRate = invoice.taxRate
        self.discount = invoice.discount
        self.invoiceDate = invoice.invoiceDate
        self.dueDate = invoice.dueDate
        self.creationDate = invoice.creationDate
        self.status = invoice.status
    }

    // Конвертер из Realm Object в Swift структуру (обновлен для использования обновленного InvoiceItemObject)
    var toStruct: Invoice {
        return Invoice(
            id: UUID(uuidString: id) ?? UUID(),
            invoiceTitle: invoiceTitle,
            client: client?.toStruct,
            // Конвертируем Realm List обратно в Swift Array
            items: Array(items.map { $0.toStruct }), // Используем Array(List) вместо reduce
            taxRate: taxRate,
            discount: discount,
            invoiceDate: invoiceDate,
            dueDate: dueDate,
            creationDate: creationDate,
            status: status
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
}

class InvoiceService: InvoiceServiceProtocol {
    private let realm: Realm

    init() throws {
        // --- БЛОК КОДА ДЛЯ МИГРАЦИИ ---
        let currentSchemaVersion: UInt64 = 2 // ⚠️ Увеличиваем версию схемы

        let config = Realm.Configuration(
            schemaVersion: currentSchemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    // Миграция со старой версии (0) до версии 1, если она была
                    // В твоем случае, если это первая миграция, ставим oldSchemaVersion < 2
                }
                
                if oldSchemaVersion < 2 {
                    // Миграция с версии 1 до версии 2: Добавлены поля
                    
                    // 1. Обновляем ClientObject
                    migration.enumerateObjects(ofType: ClientObject.className()) { oldObject, newObject in
                        // Добавленные поля в ClientObject
                        newObject!["email"] = nil
                        newObject!["phoneNumber"] = nil
                        newObject!["idNumber"] = nil
                        newObject!["faxNumber"] = nil
                        // Realm List<String> инициализируется пустым списком
                        // newObject!["tags"] = RealmSwift.List<String>()
                        newObject!["clientTypeRaw"] = ClientType.newClient.rawValue // Устанавливаем значение по умолчанию
                    }
                    
                    // 2. Обновляем InvoiceItemObject (EmbeddedObject)
                    migration.enumerateObjects(ofType: InvoiceItemObject.className()) { oldObject, newObject in
                        // Добавленные поля в InvoiceItemObject
                        newObject!["name"] = nil
                        newObject!["discountValue"] = 0.0
                        newObject!["discountTypeRaw"] = DiscountType.percentage.rawValue
                        newObject!["isTaxable"] = true
                        newObject!["unitTypeRaw"] = UnitType.item.rawValue
                    }
                }
                
                print("Realm migration finished: \(oldSchemaVersion) -> \(currentSchemaVersion)")
            }
        )
        Realm.Configuration.defaultConfiguration = config
        // ------------------------------------------------------------------------

        self.realm = try Realm()
    }

    // MARK: - CRUD Operations (Не требуют изменений)

    /// Добавляет новый счет или обновляет существующий.
    func save(invoice: Invoice) throws {
        var clientObject: ClientObject? = nil

        // ШАГ 1: Сохраняем/обновляем клиента перед сохранением счета.
        if let clientStruct = invoice.client {
            clientObject = ClientObject(client: clientStruct)

            try realm.write {
                // Сохраняем клиента. .modified гарантирует, что существующий клиент будет обновлен.
                realm.add(clientObject!, update: .modified)
            }
        }

        // ШАГ 2: Создаем Realm Object из Swift структуры, передавая ему сохраненного клиента.
        let invoiceObject = InvoiceObject(invoice: invoice, clientObject: clientObject)

        try realm.write {
            // Сохраняем счет-фактуру.
            realm.add(invoiceObject, update: .modified)
        }
    }

    /// Получает все счета, отсортированные по дате создания (самые новые сначала).
    func getAllInvoices() -> [Invoice] {
        let results = realm.objects(InvoiceObject.self)
            .sorted(byKeyPath: "creationDate", ascending: false) // Сортировка по убыванию даты

        // Маппинг Realm Results в массив Swift структур
        return results.map { $0.toStruct }
    }

    /// Получает счет по его уникальному ID.
    func getInvoice(id: UUID) -> Invoice? {
        let object = realm.object(ofType: InvoiceObject.self, forPrimaryKey: id.uuidString)
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
            existingInvoice.invoiceDate = newInvoice.invoiceDate
            existingInvoice.dueDate = newInvoice.dueDate
            existingInvoice.status = newInvoice.status
            
            // Обновляем клиента (если передан)
            if let clientStruct = newInvoice.client {
                let clientObject = ClientObject(client: clientStruct)
                realm.add(clientObject, update: .modified)
                existingInvoice.client = clientObject
            }
            
            // Обновляем items — сначала очищаем старые, потом добавляем новые
            existingInvoice.items.removeAll()
            let newItemObjects = newInvoice.items.map { InvoiceItemObject(item: $0) }
            existingInvoice.items.append(objectsIn: newItemObjects)
        }
        
        print("✅ Invoice updated: \(newInvoice.id)")
    }
}
