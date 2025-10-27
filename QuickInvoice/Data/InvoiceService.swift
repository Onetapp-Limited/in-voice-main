import Foundation
import RealmSwift

// MARK: - 1. Realm Object Definitions (Конвертация структур в Realm объекты)

// Client Object - Хранится отдельно, так как может быть привязан к нескольким счетам.
class ClientObject: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var clientName: String?
    @Persisted var address: String?
    
    // Конвертер из Swift структуры в Realm Object
    convenience init(client: Client) {
        self.init()
        // Используем id из структуры, или генерируем новый, если его нет
        self.id = client.id?.uuidString ?? UUID().uuidString
        self.clientName = client.clientName
        self.address = client.address
    }
    
    // Конвертер из Realm Object в Swift структуру
    var toStruct: Client {
        return Client(id: UUID(uuidString: id), clientName: clientName, address: address)
    }
}

// Invoice Item Object (EmbeddedObject, так как принадлежит только одному счету)
class InvoiceItemObject: EmbeddedObject {
    @Persisted var id: String = UUID().uuidString
    @Persisted var itemDescription: String = "" // Используем другое имя, чтобы избежать конфликта с 'description'
    @Persisted var quantity: Double = 0.0
    @Persisted var unitPrice: Double = 0.0
    
    // Конвертер из Swift структуры в Realm Object
    convenience init(item: InvoiceItem) {
        self.init()
        self.id = item.id.uuidString
        self.itemDescription = item.description
        self.quantity = item.quantity
        self.unitPrice = item.unitPrice
    }
    
    // Конвертер из Realm Object в Swift структуру
    var toStruct: InvoiceItem {
        return InvoiceItem(
            id: UUID(uuidString: id) ?? UUID(),
            description: itemDescription,
            quantity: quantity,
            unitPrice: unitPrice
        )
    }
}

// Invoice Object (Главный объект для хранения)
class InvoiceObject: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var invoiceTitle: String?
    // Связь с ClientObject (должен быть сохранен в Realm перед привязкой)
    @Persisted var client: ClientObject?
    @Persisted var items = RealmSwift.List<InvoiceItemObject>() // Список позиций
    @Persisted var taxRate: Double = 0.0
    @Persisted var discount: Double = 0.0
    @Persisted var invoiceDate: Date = Date()
    @Persisted var dueDate: Date = Date()
    @Persisted var creationDate: Date = Date() // Дата создания для сортировки
    @Persisted var status: String = "Paid"
    
    // Конвертер из Swift структуры в Realm Object
    convenience init(invoice: Invoice, clientObject: ClientObject?) { // Добавлен аргумент clientObject
        self.init()
        self.id = invoice.id.uuidString
        self.invoiceTitle = invoice.invoiceTitle
        
        // Теперь клиент передается уже сохраненным объектом
        self.client = clientObject
        
        // Маппинг массива структур в Realm List объектов
        self.items.append(objectsIn: invoice.items.map { InvoiceItemObject(item: $0) })
        self.taxRate = invoice.taxRate
        self.discount = invoice.discount
        self.invoiceDate = invoice.invoiceDate
        self.dueDate = invoice.dueDate
        self.creationDate = invoice.creationDate // Сохраняем дату создания
        self.status = invoice.status
    }
    
    // Конвертер из Realm Object в Swift структуру
    var toStruct: Invoice {
        return Invoice(
            id: UUID(uuidString: id) ?? UUID(),
            invoiceTitle: invoiceTitle,
            client: client?.toStruct,
            // Конвертируем Realm List обратно в Swift Array
            items: items.map { $0.toStruct }.reduce([], { $0 + [$1] }),
            taxRate: taxRate,
            discount: discount,
            invoiceDate: invoiceDate,
            dueDate: dueDate,
            creationDate: creationDate,
            status: status
        )
    }
}

// MARK: - 2. Invoice Service

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
          // --- БЛОК КОДА ДЛЯ МИГРАЦИИ (РАСКОММЕНТИРОВАТЬ ПРИ ИЗМЕНЕНИИ СХЕМЫ) ---
          /* let currentSchemaVersion: UInt64 = 1 // Текущая версия схемы. Начните с 1.
          
          let config = Realm.Configuration(
              schemaVersion: currentSchemaVersion,
              migrationBlock: { migration, oldSchemaVersion in
                  if oldSchemaVersion < 1 {
                      // Пример миграции: Если вы добавили новое поле 'taxID' в ClientObject
                      // и у него нет значения по умолчанию, вам нужно установить его:
                      // migration.enumerateObjects(ofType: ClientObject.className()) { oldObject, newObject in
                      //     newObject!["taxID"] = "N/A"
                      // }
                  }
                  
                  // Если oldSchemaVersion < 2, и т.д.
                  
                  print("Realm migration finished: \(oldSchemaVersion) -> \(currentSchemaVersion)")
              }
          )
          Realm.Configuration.defaultConfiguration = config
          */
          // ------------------------------------------------------------------------
          
          // Текущая конфигурация без явной миграции (использует схему 1)
          let config = Realm.Configuration(schemaVersion: 1)
          Realm.Configuration.defaultConfiguration = config
          
          self.realm = try Realm()
      }
    
    // MARK: - CRUD Operations
    
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
        // Используем новую инициализацию с clientObject
        let invoiceObject = InvoiceObject(invoice: invoice, clientObject: clientObject)
        
        try realm.write {
            // Сохраняем счет-фактуру.
            // .modified указывает Realm обновить объект, если он уже существует (по Primary Key)
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
            return // Запись не найдена, выходим без ошибки
        }
        
        try realm.write {
            // Клиент останется в базе, если не нужно удалять его вместе со счетом
            realm.delete(objectToDelete)
        }
    }
    
    /// Удаляет все счета из базы данных.
    func deleteAllInvoices() throws {
        let invoiceObjectsToDelete = realm.objects(InvoiceObject.self)
        let clientObjectsToDelete = realm.objects(ClientObject.self) // Также удаляем всех клиентов для чистоты
        
        try realm.write {
            realm.delete(invoiceObjectsToDelete)
            realm.delete(clientObjectsToDelete)
        }
    }
}
