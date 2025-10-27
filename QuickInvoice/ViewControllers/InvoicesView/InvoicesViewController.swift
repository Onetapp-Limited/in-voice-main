import UIKit
import SnapKit

class InvoicesViewController: UIViewController {
    
    // MARK: - UI Elements
    
    lazy var invoiceTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.background // ✅ Замена .systemBackground
        return tableView
    }()
    
    lazy var invoicesSearchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search Invoices or Clients"
        searchBar.barTintColor = UIColor.background // Фон SearchBar
        searchBar.searchBarStyle = .minimal // Для лучшего контроля цветов
        
        // Установка цвета текста и фона поля ввода
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor.surface // ✅ Используем Surface для поля ввода
            textField.textColor = UIColor.primaryText
        }
        return searchBar
    }()
    
    // Новая градиентная кнопка
    lazy var createInvoiceButton: GradientButton = {
        let button = GradientButton(type: .custom)
        
        // Настройка текста
        button.setTitle("Create New Invoice", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        // Настройка иконки плюсика
        let plusImage = UIImage(systemName: "plus")?.withRenderingMode(.alwaysTemplate)
        button.setImage(plusImage, for: .normal)
        button.tintColor = .white
        
        // Расположение текста и иконки
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: -10)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 10)
        
        button.addTarget(self, action: #selector(createInvoiceButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Data Properties
    
    var invoices: [Invoice] = [] // Предполагается, что Invoice и Client определены
    var filteredInvoices: [Invoice] = []
    var selectedInvoice: Invoice!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.background // ✅ Замена .systemBackground
        setupUI()
        setup()
    }
    
    // MARK: - Actions
    
    @objc func createInvoiceButtonTapped() {
        print("Create New Invoice button tapped!")
        // Здесь ваша логика создания нового инвойса
    }
}

// MARK: - Setup (UI и Data)
extension InvoicesViewController {
    
    func setupUI() {
        // 1. Настройка Navigation Bar
        title = "Invoices"
        
        // Установка цвета фона Navigation Bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.background
        appearance.titleTextAttributes = [.foregroundColor: UIColor.primaryText]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        
        // 2. Установка Search Bar, TableView и Кнопки
        view.addSubview(invoicesSearchBar)
        view.addSubview(invoiceTableView)
        view.addSubview(createInvoiceButton) // Добавляем кнопку
        
        // Констрейнты для Search Bar
        invoicesSearchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        
        // Констрейнты для Кнопки (внизу экрана)
        createInvoiceButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(20)
            make.height.equalTo(50)
        }
        
        // Констрейнты для TableView (теперь он заканчивается над кнопкой)
        invoiceTableView.snp.makeConstraints { make in
            make.top.equalTo(invoicesSearchBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            // Отступ снизу, чтобы TableView не перекрывал кнопку
            make.bottom.equalTo(createInvoiceButton.snp.top).offset(-10)
        }
    }
    
    func setup() {
        invoiceTableView.delegate = self
        invoiceTableView.dataSource = self
        
        invoicesSearchBar.delegate = self
        
        invoiceTableView.register(InvoiceTableViewCell.self, forCellReuseIdentifier: InvoiceTableViewCell.reuseIdentifier)
        
        invoices = fetchInvoices()
        
        invoices = invoices.sorted(by: { (i1, i2) -> Bool in
            i1.invoiceTitle?.lowercased() ?? "" < i2.invoiceTitle?.lowercased() ?? ""
        })
        filteredInvoices = invoices
    }
    
    private func fetchInvoices() -> [Invoice] {
        // Временные тестовые данные для демонстрации работы TableView
        return [
            Invoice(invoiceTitle: "Project Alpha", client: Client(clientName: "Client A"), invoiceDate: "Oct 20, 2025"),
            Invoice(invoiceTitle: "Monthly Retainer", client: Client(clientName: "Client B"), invoiceDate: "Oct 15, 2025"),
            Invoice(invoiceTitle: "Website Redesign", client: Client(clientName: "Client C"), invoiceDate: "Sep 28, 2025")
        ]
    }
    
    private func deleteInvoice(invoice: Invoice) {
        // Логика удаления
    }
}

// MARK: - Search Bar Delegate
extension InvoicesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredInvoices = searchText.isEmpty ? invoices : invoices.filter({ (invoice) -> Bool in
            if invoice.invoiceTitle?.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil {
                return true
            }
            if invoice.client?.clientName?.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil {
                return true
            }
            return false
        })
        invoiceTableView.reloadData()
    }
}

// MARK: - Table View Delegate and Data Source
extension InvoicesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredInvoices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = invoiceTableView.dequeueReusableCell(withIdentifier: InvoiceTableViewCell.reuseIdentifier, for: indexPath) as! InvoiceTableViewCell
        
        let currentInvoice = filteredInvoices[indexPath.row]
        
        if let client = currentInvoice.client {
            cell.clientNameLabel.text = client.clientName ?? ""
        } else {
            cell.clientNameLabel.text = ""
        }
        
        cell.invoiceTitleLabel.text = currentInvoice.invoiceTitle ?? ""
        cell.dateLabel.text = currentInvoice.invoiceDate ?? ""
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            deleteInvoice(invoice: filteredInvoices[indexPath.row])
            filteredInvoices.remove(at: indexPath.row)
            invoiceTableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedInvoice = filteredInvoices[indexPath.row]
        showInvoiceDetailVC()
    }
    
}

// MARK: - View Controller Flow
extension InvoicesViewController {
    func showInvoiceDetailVC() {
        // Здесь должна быть ваша логика инициализации NewInvoiceViewController
        // let vc = NewInvoiceViewController()
        // vc.modalPresentationStyle = .overFullScreen
        // vc.curInvoice = selectedInvoice
        // self.present(vc, animated: true)
    }
}
