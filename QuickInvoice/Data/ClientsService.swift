import Foundation
import RealmSwift

class ClientsService {
    
    // Получаем экземпляр Realm, который уже сконфигурирован в InvoiceService.
    private let realm: Realm
    
    // Инициализатор, который должен быть использован после инициализации InvoiceService,
    // чтобы Realm был уже настроен.
    init() throws {
        // Realm.Configuration.defaultConfiguration должен быть установлен к этому моменту
        self.realm = try Realm()
    }
    
    // MARK: - CRUD Operations
    
    /// Добавляет нового клиента или обновляет существующего.
    func save(client: Client) throws {
        let clientObject = ClientObject(client: client)
        
        try realm.write {
            // Используем .modified для обновления существующего клиента по primaryKey
            realm.add(clientObject, update: .modified)
        }
    }
    
    /// Обновляет существующего клиента.
    func updateClient(_ newClient: Client) throws {
        guard let existingClient = realm.object(ofType: ClientObject.self, forPrimaryKey: newClient.id?.uuidString) else {
            print("❌ Client not found with id: \(newClient.id?.uuidString ?? "N/A")")
            return
        }
        
        // Обновляем поля существующего объекта в транзакции
        try realm.write {
            existingClient.clientName = newClient.clientName
            existingClient.email = newClient.email
            existingClient.phoneNumber = newClient.phoneNumber
            existingClient.address = newClient.address
            existingClient.idNumber = newClient.idNumber
            existingClient.faxNumber = newClient.faxNumber
            
            // Обновление массива тэгов
            existingClient.tags.removeAll()
            existingClient.tags.append(objectsIn: newClient.tags)
            
            // Обновление типа клиента
            existingClient.clientTypeRaw = newClient.clientType.rawValue
        }
    }
    
    /// Получает всех сохраненных клиентов.
    func getAllClients() -> [Client] {
        let results = realm.objects(ClientObject.self)
            // Можно добавить сортировку, например, по имени
            .sorted(byKeyPath: "clientName", ascending: true)
        
        // Маппинг Realm Results в массив Swift структур
        return results.map { $0.toStruct }
    }
    
    /// Получает клиента по его уникальному ID.
    func getClient(id: UUID) -> Client? {
        let object = realm.object(ofType: ClientObject.self, forPrimaryKey: id.uuidString)
        return object?.toStruct
    }
    
    /// Удаляет клиента по его ID.
    func deleteClient(id: UUID) throws {
        guard let objectToDelete = realm.object(ofType: ClientObject.self, forPrimaryKey: id.uuidString) else {
            return // Клиент не найден, ничего не делаем
        }
        
        try realm.write {
            realm.delete(objectToDelete)
        }
    }
    
    /// Удаляет всех клиентов из базы данных.
    func deleteAllClients() throws {
        let clientObjectsToDelete = realm.objects(ClientObject.self)
        
        try realm.write {
            realm.delete(clientObjectsToDelete)
        }
    }
}
