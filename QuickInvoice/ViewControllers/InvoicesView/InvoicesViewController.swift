import UIKit
import SnapKit

class InvoicesViewController: UIViewController {
    lazy var invoiceTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        return tableView
    }()
    
    lazy var invoicesSearchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search Invoices or Clients"
        return searchBar
    }()
    
    var invoices: [Invoice] = []
    var filteredInvoices: [Invoice] = []
    var selectedInvoice: Invoice!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
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
    
    // Новый метод для добавления и настройки UI
    func setupUI() {
        // Добавляем Search Bar в Navigation Bar, если используете Navigation Controller.
        // Или добавляем его как Header TableView, если не в Navigation Controller.
        // Я добавлю его как Header, чтобы сохранить структуру изначального кода:
        
        // 1. Настройка Navigation Bar
        title = "Invoices"
        let dismissButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf))
        navigationItem.leftBarButtonItem = dismissButton
        
        // 2. Установка Search Bar и TableView
        view.addSubview(invoicesSearchBar)
        view.addSubview(invoiceTableView)
        
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
        
        // ✅ Регистрируем класс, а не Nib
        invoiceTableView.register(InvoiceTableViewCell.self, forCellReuseIdentifier: InvoiceTableViewCell.reuseIdentifier)
        
        // Заглушка для функции, так как ее нет в предоставленном коде
        invoices = fetchInvoices()
        
        invoices = invoices.sorted(by: { (i1, i2) -> Bool in
            i1.invoiceTitle?.lowercased() ?? "" < i2.invoiceTitle?.lowercased() ?? ""
        })
        filteredInvoices = invoices
    }
    
    // Заглушка для fetchInvoices и Invoice (должны быть предоставлены вами)
    private func fetchInvoices() -> [Invoice] {
        // Добавьте здесь логику загрузки счетов (например, из Core Data/Realm/JSON)
        // Возвращаем пустой массив, чтобы код компилировался
        return []
    }
    
    private func deleteInvoice(invoice: Invoice) {
        // Добавьте здесь логику удаления счета из базы данных
    }
}

// MARK: - Extensions (Остаются прежними, но используют новый reuseIdentifier)

// MARK: - Search Bar Delegate
extension InvoicesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // ... (логика поиска)
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
        // ✅ Используем InvoiceTableViewCell.reuseIdentifier
        let cell = invoiceTableView.dequeueReusableCell(withIdentifier: InvoiceTableViewCell.reuseIdentifier, for: indexPath) as! InvoiceTableViewCell
        
        // Убедимся, что filteredInvoices используется для получения данных
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

// MARK: - View Controller Flow (Удаляем зависимость от Storyboard)
extension InvoicesViewController {
    func showInvoiceDetailVC() {
        // 🛑 Удаляем загрузку из Storyboard
//        let vc = NewInvoiceViewController()
//        
//        vc.modalPresentationStyle = .overFullScreen
//        vc.curInvoice = selectedInvoice
//        
//        self.present(vc, animated: true)
    }
}
