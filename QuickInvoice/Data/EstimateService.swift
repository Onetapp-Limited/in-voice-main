import Foundation
import RealmSwift

class EstimateObject: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    // Используем estimateTitle для логического соответствия
    @Persisted var estimateTitle: String?
    @Persisted var client: ClientObject?
    @Persisted var items = RealmSwift.List<InvoiceItemObject>()
    @Persisted var taxRate: Double = 0.0
    @Persisted var discount: Double = 0.0
    
    // Тип скидки
    @Persisted var discountTypeRaw: String = DiscountType.fixedAmount.rawValue
    
    @Persisted var creationDate: Date = Date()
    
    // Статус сметы (Draft, Sent, Accepted, Rejected) - используем тот же InvoiceStatus
    @Persisted var statusRaw: String = InvoiceStatus.draft.rawValue
    @Persisted var currencyRaw: String = Currency.USD.rawValue
    
    @Persisted var totalAmount: String = "" // Строковое представление Grand Total

    // Конвертер из Swift структуры Estimate в Realm Object
    convenience init(estimate: Estimate, clientObject: ClientObject?) {
        self.init()
        self.id = estimate.id.uuidString
        self.estimateTitle = estimate.estimateTitle // NOTE: Используем invoiceTitle из Estimate
        
        self.client = clientObject
        
        self.items.append(objectsIn: estimate.items.map { InvoiceItemObject(item: $0) })
        self.taxRate = estimate.taxRate
        self.discount = estimate.discount
        
        self.discountTypeRaw = estimate.discountType.rawValue
        
        self.creationDate = estimate.creationDate
        
        self.statusRaw = estimate.status.rawValue
        self.currencyRaw = estimate.currency.rawValue
        
        self.totalAmount = estimate.totalAmount
    }

    // Конвертер из Realm Object в Swift структуру Estimate
    var toStruct: Estimate {
        let status = InvoiceStatus(rawValue: statusRaw) ?? .draft
        let currency = Currency(rawValue: currencyRaw) ?? .USD
        let discountType = DiscountType(rawValue: discountTypeRaw) ?? .fixedAmount

        // NOTE: Используем estimateTitle для инициализации invoiceTitle в Estimate
        return Estimate(
            id: UUID(uuidString: id) ?? UUID(),
            estimateTitle: estimateTitle,
            client: client?.toStruct,
            items: Array(items.map { $0.toStruct }),
            taxRate: taxRate,
            discount: discount,
            discountType: discountType,
            creationDate: creationDate,
            status: status,
            currency: currency,
            totalAmount: totalAmount
        )
    }
}

class EstimateService {
    private let realm: Realm

    init() throws {
        // todo test111 избыточный код -- нужно только один раз устанавливать Realm.Configuration.defaultConfiguration = config
        /// уже УБЕДИЛСЯ ЧТО InvoiceService точно инитится при запуске апп
        
        // ⚠️ УВЕЛИЧИВАЕМ ВЕРСИЮ СХЕМЫ!
        // Если ваш InvoiceService использовал версию 4, для добавления EstimateObject
        // в ту же схему Realm нужно использовать версию 5 (или выше).
//        let currentSchemaVersion: UInt64 = 5
//
//        let config = Realm.Configuration(
//            schemaVersion: currentSchemaVersion,
//            migrationBlock: { migration, oldSchemaVersion in
//                
//                if oldSchemaVersion < currentSchemaVersion {
//                    // При добавлении нового класса EstimateObject вручную миграция не требуется,
//                    // Realm автоматически добавит новый класс.
//                    // Если у вас будут изменения в EstimateObject, логика миграции будет здесь.
//                    print("Realm migration finished: \(oldSchemaVersion) -> \(currentSchemaVersion)")
//                }
//            }
//        )
//        Realm.Configuration.defaultConfiguration = config
        
        self.realm = try Realm()
    }

    // MARK: - CRUD Operations

    /// Добавляет новую смету или обновляет существующую.
    func save(estimate: Estimate) throws {
        var clientObject: ClientObject? = nil

        // ШАГ 1: Сохраняем/обновляем клиента (общий код с InvoiceService).
        if let clientStruct = estimate.client {
            clientObject = ClientObject(client: clientStruct)

            try realm.write {
                realm.add(clientObject!, update: .modified)
            }
        }

        // ШАГ 2: Создаем Realm Object из Swift структуры, передавая ему сохраненного клиента.
        let estimateObject = EstimateObject(estimate: estimate, clientObject: clientObject)

        try realm.write {
            // Сохраняем смету.
            realm.add(estimateObject, update: .modified)
        }
    }

    /// Получает все сметы.
    func getAllEstimates() -> [Estimate] {
        let results = realm.objects(EstimateObject.self)
            .sorted(byKeyPath: "creationDate", ascending: false)

        return results.map { $0.toStruct }
    }

    /// Получает смету по ее уникальному ID.
    func getEstimate(id: UUID) -> Estimate? {
        let object = realm.object(ofType: EstimateObject.self, forPrimaryKey: id.uuidString)
        return object?.toStruct
    }

    /// Удаляет смету по ее ID.
    func deleteEstimate(id: UUID) throws {
        guard let objectToDelete = realm.object(ofType: EstimateObject.self, forPrimaryKey: id.uuidString) else {
            return
        }

        try realm.write {
            realm.delete(objectToDelete)
        }
    }

    /// Удаляет все сметы из базы данных.
    func deleteAllEstimates() throws {
        let estimateObjectsToDelete = realm.objects(EstimateObject.self)

        try realm.write {
            realm.delete(estimateObjectsToDelete)
        }
    }
    
    // Метод для обновления
    func updateEstimate(_ newEstimate: Estimate) throws {
        guard let existingEstimate = realm.object(ofType: EstimateObject.self, forPrimaryKey: newEstimate.id.uuidString) else {
            print("❌ Estimate not found with id: \(newEstimate.id)")
            return
        }
        
        try realm.write {
            // Обновляем простые поля
            existingEstimate.estimateTitle = newEstimate.estimateTitle
            existingEstimate.taxRate = newEstimate.taxRate
            existingEstimate.discount = newEstimate.discount
            existingEstimate.discountTypeRaw = newEstimate.discountType.rawValue
            existingEstimate.creationDate = newEstimate.creationDate
            
            // Обновление статуса и валюты
            existingEstimate.statusRaw = newEstimate.status.rawValue
            existingEstimate.currencyRaw = newEstimate.currency.rawValue
            existingEstimate.totalAmount = newEstimate.totalAmount
            
            // Обновляем клиента
            if let clientStruct = newEstimate.client {
                let clientObject = ClientObject(client: clientStruct)
                realm.add(clientObject, update: .modified)
                existingEstimate.client = clientObject
            } else {
                existingEstimate.client = nil
            }
            
            // Обновляем items — сначала очищаем старые, потом добавляем новые
            existingEstimate.items.removeAll()
            let newItemObjects = newEstimate.items.map { InvoiceItemObject(item: $0) }
            existingEstimate.items.append(objectsIn: newItemObjects)
        }
        
        print("✅ Estimate updated: \(newEstimate.id)")
    }
}
