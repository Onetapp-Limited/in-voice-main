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
    
    @objc func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
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
        
        let dismissButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf))
        dismissButton.tintColor = UIColor.primary // ✅ Цвет кнопки
        navigationItem.leftBarButtonItem = dismissButton
        
        // 2. Установка Search Bar и TableView
        view.addSubview(invoicesSearchBar)
        view.addSubview(invoiceTableView)
        
        // Констрейнты для Search Bar
        invoicesSearchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        
        // Констрейнты для TableView
        invoiceTableView.snp.makeConstraints { make in
            make.top.equalTo(invoicesSearchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
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
        return []
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

