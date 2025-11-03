import UIKit
import SnapKit

class ClientsViewController: UIViewController {
    
    enum ClientSortOption {
        case nameAscending
        case dateCreatedDescending
        case dateCreatedDescendingOldest
        case type
        
        var title: String {
            switch self {
            case .nameAscending: return "Name"
            case .dateCreatedDescending: return "Date Created (Newest)"
            case .dateCreatedDescendingOldest: return "Date Created (Oldest)"
            case .type: return "Client Type"
            }
        }
    }
    
    // MARK: - Data Properties
    
    private var invoiceService: InvoiceService? {
        do {
            return try InvoiceService()
        } catch {
            print("Failed to initialize InvoiceService: \(error)")
            return nil
        }
    }
    
    var clientsService: ClientsService? {
        do {
            return try ClientsService()
        } catch {
            return nil
        }
    }
    
    // Входные данные (Все счета), передаются снаружи
    var allInvoices: [Invoice] = [] {
        didSet {
//            let uniqueClients = Set(allInvoices.compactMap { $0.client }.filter { $0.id != nil })
//            allClients = Array(uniqueClients).sorted(by: { $0.clientName ?? "" < $1.clientName ?? "" }) + clientsFromDB
            
            let clientsFromDB = clientsService?.getAllClients() ?? []
            allClients = clientsFromDB
            filteredClients = allClients
        }
    }
    
    private var allClients: [Client] = []
    
    var filteredClients: [Client] = [] {
        didSet {
            // Обновляем состояние пустого экрана
            updateEmptyState()
            clientsTableView.reloadData()
        }
    }
    
    private var currentSortOption: ClientSortOption = .nameAscending {
        didSet {
            sortClients(by: currentSortOption)
        }
    }
    
    // MARK: - UI Elements
    
    lazy var clientsTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.background
        tableView.rowHeight = 68 // Чуть меньше, чем для инвойсов
        tableView.isHidden = true // Изначально скрыта
        return tableView
    }()
    
    // Элемент для выпадающего меню сортировки (заменяет Search Bar)
    lazy var sortButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.primaryText
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        button.setTitle("Sort: Name", for: .normal)
        button.setImage(UIImage(systemName: "arrow.up.arrow.down"), for: .normal)
        button.semanticContentAttribute = .forceRightToLeft // Иконка справа
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        return button
    }()

    // Кнопка внизу экрана
    lazy var createClientButton: GradientButton = {
        let button = GradientButton(type: .custom)
        button.setTitle("Add New Client", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        let plusConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let plusImage = UIImage(systemName: "plus", withConfiguration: plusConfig)?
            .withRenderingMode(.alwaysTemplate)
        button.setImage(plusImage, for: .normal)
        button.tintColor = .white
        
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: -10)
        button.addTarget(self, action: #selector(createClientButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // Заглушка (Empty State) с системной иконкой
    lazy var emptyStateView: UIView = {
        let view = UIView()
        
        // 1. Изображение
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 80, weight: .ultraLight) // Делаем иконку крупной и тонкой
        let iconImage = UIImage(systemName: "person.3", withConfiguration: symbolConfig)
        
        let iconImageView = UIImageView(image: iconImage)
        iconImageView.tintColor = UIColor.systemGray3 // Мягкий, не отвлекающий цвет
        iconImageView.contentMode = .scaleAspectFit
        
        // 2. Текстовая метка (ваша существующая)
        let label = UILabel()
        label.text = "Your clients will appear here. Add your first client to get started!"
        label.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        label.textColor = UIColor.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        
        // 3. StackView для вертикального размещения
        let stackView = UIStackView(arrangedSubviews: [iconImageView, label])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 20 // Пространство между иконкой и текстом
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(40) // Отступы для текста
            make.center.equalToSuperview()
        }
        
        view.isHidden = true
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.background
        setupNavigationBar()
        setupUI()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Обновляем состояние таблицы (если данные уже были установлены)
        fetchInvoices()
        updateEmptyState()
    }
    
    // MARK: - Setup
    
    private func fetchInvoices() {
        let fetchedInvoices: [Invoice] = invoiceService?.getAllInvoices() ?? []
        allInvoices = fetchedInvoices.sorted(by: { $0.creationDate > $1.creationDate })
    }
    
    private func setupNavigationBar() {
        // Копируем стиль InvoicesViewController
        
        // 1. Левый элемент: Иконка + Title "Clients"
        let logoImage = UIImage(systemName: "person.3.fill")?.withTintColor(UIColor.accent, renderingMode: .alwaysOriginal)
        let logoImageView = UIImageView(image: logoImage)
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.snp.makeConstraints { make in make.size.equalTo(24) }
        
        let titleLabel = UILabel()
        titleLabel.text = "Clients" // Изменено на "Clients"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = UIColor.primaryText
        
        let leftStack = UIStackView(arrangedSubviews: [UIView(), logoImageView, titleLabel, UIView()])
        leftStack.axis = .horizontal
        leftStack.spacing = 8
        
        let leftBarItem = UIBarButtonItem(customView: leftStack)
        navigationItem.leftBarButtonItem = leftBarItem
        
        // 2. Правый элемент: PRO Badge
        let proButton = UIButton(type: .custom)
        proButton.setTitle("PRO", for: .normal)
        proButton.setTitleColor(.white, for: .normal)
        proButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        
        let starIcon = UIImage(systemName: "crown.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold))
        proButton.setImage(starIcon, for: .normal)
        proButton.tintColor = .white
        
        proButton.backgroundColor = UIColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1.0)
        proButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        proButton.layer.cornerRadius = 10
        proButton.clipsToBounds = true
        
        proButton.addTarget(self, action: #selector(proBadgeTapped), for: .touchUpInside)
        
        let rightBarItem = UIBarButtonItem(customView: proButton)
        navigationItem.rightBarButtonItem = rightBarItem
        
        // 3. Общие настройки Navigation Bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.background
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.isTranslucent = false
    }
    
    private func setupUI() {
        
        view.addSubview(sortButton)
        view.addSubview(clientsTableView)
        view.addSubview(createClientButton)
        view.addSubview(emptyStateView)
        
        // Констрейнты для Кнопки (снизу)
        createClientButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(24)
            make.height.equalTo(50)
        }
        
        // Констрейнты для Кнопки сортировки (заменяет Search Bar)
        sortButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        // Констрейнты для TableView (заканчивается над кнопкой)
        clientsTableView.snp.makeConstraints { make in
            make.top.equalTo(sortButton.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(createClientButton.snp.top).offset(-16)
        }
        
        // Констрейнты для Заглушки (накладывается на таблицу)
        emptyStateView.snp.makeConstraints { make in
            make.edges.equalTo(clientsTableView)
        }
    }
    
    private func setup() {
        clientsTableView.delegate = self
        clientsTableView.dataSource = self
        clientsTableView.register(ClientTableViewCell.self, forCellReuseIdentifier: ClientTableViewCell.reuseIdentifier)
        
        // Настройка меню для кнопки сортировки
        setupSortMenu()
    }
    
    private func updateEmptyState() {
        let isEmpty = filteredClients.isEmpty
        clientsTableView.isHidden = isEmpty
        emptyStateView.isHidden = !isEmpty
    }
    
    // MARK: - Sorting Logic
    
    private func setupSortMenu() {
        // Меню для сортировки
        let sortByNameAction = UIAction(title: ClientSortOption.nameAscending.title) { [weak self] _ in
            self?.currentSortOption = .nameAscending
            self?.sortButton.setTitle(ClientSortOption.nameAscending.title, for: .normal)
        }
        
        let sortByDateAction = UIAction(title: ClientSortOption.dateCreatedDescending.title) { [weak self] _ in
            self?.currentSortOption = .dateCreatedDescending
            self?.sortButton.setTitle(ClientSortOption.dateCreatedDescending.title, for: .normal)
        }
        
        let sortByDateActionReversed = UIAction(title: ClientSortOption.dateCreatedDescendingOldest.title) { [weak self] _ in
            self?.currentSortOption = .dateCreatedDescendingOldest
            self?.sortButton.setTitle(ClientSortOption.dateCreatedDescendingOldest.title, for: .normal)
        }
        
        let sortByTypeAction = UIAction(title: ClientSortOption.type.title) { [weak self] _ in
            self?.currentSortOption = .type
            self?.sortButton.setTitle(ClientSortOption.type.title, for: .normal)
        }
        
        let menu = UIMenu(title: "Sort Clients By", children: [sortByNameAction, sortByDateAction, sortByDateActionReversed, sortByTypeAction])
        sortButton.menu = menu
        sortButton.showsMenuAsPrimaryAction = true
    }
    
    private func sortClients(by option: ClientSortOption) {
        switch option {
        case .nameAscending:
            // Сортируем по имени (A-Z)
            filteredClients.sort { ($0.clientName ?? "") < ($1.clientName ?? "") }
        case .dateCreatedDescending:
            // Сортируем по дате создания.
            // NOTE: Client не имеет поля creationDate. Чтобы отсортировать по дате создания,
            // мы используем дату создания ПЕРВОГО счета, связанного с клиентом.
            filteredClients.sort { client1, client2 in
                // Ищем самую раннюю дату создания счета для каждого клиента
                let date1 = allInvoices.filter { $0.client?.id == client1.id }
                                        .map { $0.creationDate }
                                        .min()
                let date2 = allInvoices.filter { $0.client?.id == client2.id }
                                        .map { $0.creationDate }
                                        .min()
                // Сортируем от нового к старому (date2 < date1)
                return date1 ?? Date.distantPast > date2 ?? Date.distantPast
            }
        case .dateCreatedDescendingOldest:
            filteredClients.sort { client1, client2 in
                let date1 = allInvoices.filter { $0.client?.id == client1.id }
                                        .map { $0.creationDate }
                                        .min()
                let date2 = allInvoices.filter { $0.client?.id == client2.id }
                                        .map { $0.creationDate }
                                        .min()
                return date1 ?? Date.distantPast < date2 ?? Date.distantPast
            }
        case .type:
            // Сортируем по ClientType (имя в качестве вторичного ключа)
            filteredClients.sort {
                if $0.clientType.rawValue != $1.clientType.rawValue {
                    return $0.clientType.rawValue < $1.clientType.rawValue
                }
                return ($0.clientName ?? "") < ($1.clientName ?? "")
            }
        }
        clientsTableView.reloadData()
    }

    // MARK: - Actions
    
    @objc func createClientButtonTapped() {
        let clientToEdit = Client()
        let newClientVC = NewClientViewController(client: clientToEdit)
        newClientVC.delegate = self
        let navController = UINavigationController(rootViewController: newClientVC)

        present(navController, animated: true)
    }
    
    @objc func proBadgeTapped() {
        let alert = UIAlertController(title: "Go PRO", message: "Unlock advanced features!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Table View Delegate and Data Source
extension ClientsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredClients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ClientTableViewCell.reuseIdentifier, for: indexPath) as? ClientTableViewCell else {
            return UITableViewCell()
        }
        
        let client = filteredClients[indexPath.row]
        cell.configure(with: client)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedClient = filteredClients[indexPath.row]
        let newClientVC = NewClientViewController(client: selectedClient)
        newClientVC.delegate = self
        let navController = UINavigationController(rootViewController: newClientVC)

        present(navController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            self?.handleDeleteClient(at: indexPath)
            completionHandler(true)
        }
        
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash.fill")
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        
        configuration.performsFirstActionWithFullSwipe = true
        
        return configuration
    }
    
    private func handleDeleteClient(at indexPath: IndexPath) {
        let clientToDelete = filteredClients[indexPath.row]
        
        guard let clientID = clientToDelete.id else {
            print("❌ Error: Attempted to delete client without an ID.")
            return
        }
        
        do {
            try clientsService?.deleteClient(id: clientID)
            fetchInvoices()
            print("✅ Client successfully deleted: \(clientID.uuidString)")
        } catch {
            print("🛑 Error deleting client: \(error)")
        }
    }
}

extension ClientsViewController: NewClientViewControllerDelegate {
    func didSaveClient(_ client: Client) {
        print("Client saved: \(client)")
        do {
            if let clientID = client.id, clientsService?.getClient(id: clientID) != nil {
                print("updateClient")
                try clientsService?.updateClient(client)
            } else {
                print("saveClient")
                try clientsService?.save(client: client)
            }
            fetchInvoices()
        } catch {
            print("Error saving client: \(error)")
        }
    }
}
