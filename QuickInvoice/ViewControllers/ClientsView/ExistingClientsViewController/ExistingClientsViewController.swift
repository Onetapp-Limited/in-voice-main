import UIKit
import SnapKit

protocol ExistingClientsViewControllerDelegate: AnyObject {
    func didSelectClient(_ client: Client)
}

class ExistingClientsViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: ExistingClientsViewControllerDelegate?
    
    private var clientsService: ClientsService? {
        do {
            return try ClientsService()
        } catch {
            print("Failed to initialize ClientsService: \(error)")
            return nil
        }
    }
    
    private var allClients: [Client] = []
    
    private var filteredClients: [Client] = [] {
        didSet {
            clientsTableView.reloadData()
        }
    }
    
    // MARK: - UI Elements
    
    lazy var clientsTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.background
        tableView.rowHeight = 60
        return tableView
    }()
    
    lazy var clientsSearchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search Clients"
        searchBar.barTintColor = UIColor.background
        searchBar.searchBarStyle = .minimal
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor.surface
            textField.textColor = UIColor.primaryText
            textField.layer.cornerRadius = 10
            textField.clipsToBounds = true
        }
        return searchBar
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.background
        setupNavigationBar()
        setupUI()
        setup()
        setupTapToDismissKeyboard()
        
        // Загружаем клиентов
        allClients = fetchClients()
        filteredClients = allClients
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        title = "Select Client"
        
        // Кнопка Cancel
        let cancelButton = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        cancelButton.tintColor = .accent
        navigationItem.leftBarButtonItem = cancelButton
        
        // Настройки Navigation Bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.background
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.isTranslucent = false
    }
    
    private func setupUI() {
        view.addSubview(clientsSearchBar)
        view.addSubview(clientsTableView)
        
        // Констрейнты для Search Bar
        clientsSearchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        
        // Констрейнты для TableView
        clientsTableView.snp.makeConstraints { make in
            make.top.equalTo(clientsSearchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func setup() {
        clientsTableView.delegate = self
        clientsTableView.dataSource = self
        
        clientsSearchBar.delegate = self
        
        clientsTableView.register(ClientTableViewCell.self, forCellReuseIdentifier: "ClientCell")
    }
    
    // MARK: - Data Fetching
    
    private func fetchClients() -> [Client] {
        let fetchedClients: [Client] = clientsService?.getAllClients() ?? []
        return fetchedClients
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Keyboard Handling
    
    private func setupTapToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func endEditing() {
        view.endEditing(true)
    }
}

// MARK: - Table View Delegate and Data Source

extension ExistingClientsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredClients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ClientCell", for: indexPath) as? ClientTableViewCell else {
            return UITableViewCell()
        }
        
        let client = filteredClients[indexPath.row]
        cell.configure(with: client)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedClient = filteredClients[indexPath.row]
        
        delegate?.didSelectClient(selectedClient)
        
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Search Bar Delegate

extension ExistingClientsViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredClients = allClients
        } else {
            filteredClients = allClients.filter { client in
                let nameMatch = client.clientName?.range(of: searchText, options: .caseInsensitive) != nil
                let emailMatch = client.email?.range(of: searchText, options: .caseInsensitive) != nil
                let phoneMatch = client.phoneNumber?.range(of: searchText, options: .caseInsensitive) != nil
                return nameMatch || emailMatch || phoneMatch
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        filteredClients = allClients
    }
}
