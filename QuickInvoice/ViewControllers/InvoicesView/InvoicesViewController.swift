import UIKit
import SnapKit

class InvoicesViewController: UIViewController {
    
    // MARK: - Data Grouping Properties
    private var groupedInvoices: [String: [Invoice]] = [:]
    private var sortedSections: [String] = []
    
    private var allInvoices: [Invoice] = []
    
    var filteredInvoices: [Invoice] = [] {
        didSet {
            groupInvoicesByMonth(filteredInvoices)
            invoiceTableView.reloadData()
        }
    }
    
    private var invoiceService: InvoiceService? {
        do {
            return try InvoiceService()
        } catch {
            print("Failed to initialize InvoiceService: \(error)")
            return nil
        }
    }
    
    // MARK: - UI Elements (Оставлены без изменений, как в финальной версии)
    
    lazy var invoiceTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.background
        tableView.rowHeight = 85
        return tableView
    }()
    
    lazy var invoicesSearchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search Invoices"
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
    
    lazy var createInvoiceButton: GradientButton = {
        let button = GradientButton(type: .custom)
        button.setTitle("Create New Invoice", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        let plusConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let plusImage = UIImage(systemName: "plus", withConfiguration: plusConfig)?
            .withRenderingMode(.alwaysTemplate)
        button.setImage(plusImage, for: .normal)
        button.tintColor = .white
        
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: -10)
        
        button.addTarget(self, action: #selector(createInvoiceButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.background
        setupNavigationBar()
        setupUI()
        setup()
        setupTapToDismissKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Обновляем данные при каждом появлении
        allInvoices = fetchInvoices()
        filteredInvoices = allInvoices
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        
        // 1. Левый элемент: Иконка + Title "InvoiceFly"
        let logoImage = UIImage(systemName: "doc.text.image.fill")?.withTintColor(.accent, renderingMode: .alwaysOriginal)
        let logoImageView = UIImageView(image: logoImage)
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.snp.makeConstraints { make in make.size.equalTo(24) }
        
        let titleLabel = UILabel()
        titleLabel.text = "Invoices"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .primaryText
        
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
    
    func setupUI() {
        
        view.addSubview(invoicesSearchBar)
        view.addSubview(invoiceTableView)
        view.addSubview(createInvoiceButton)
        
        // Констрейнты для Search Bar
        invoicesSearchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        
        // Констрейнты для Кнопки (снизу)
        createInvoiceButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(24)
            make.height.equalTo(50)
        }
        
        // Констрейнты для TableView (заканчивается над кнопкой)
        invoiceTableView.snp.makeConstraints { make in
            make.top.equalTo(invoicesSearchBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(createInvoiceButton.snp.top).offset(-16)
        }
    }
    
    func setup() {
        invoiceTableView.delegate = self
        invoiceTableView.dataSource = self
        
        invoicesSearchBar.delegate = self
        
        invoiceTableView.register(InvoiceTableViewCell.self, forCellReuseIdentifier: InvoiceTableViewCell.reuseIdentifier)
    }
    
    // MARK: - Data Logic (Grouping)
    
    private func groupInvoicesByMonth(_ invoices: [Invoice]) {
        groupedInvoices = Dictionary(grouping: invoices) { invoice -> String in
            // Группируем по месяцу и году создания счета
            return DateFormatter.monthYear.string(from: invoice.creationDate)
        }
        
        // Сортируем ключи (секции) по дате (самый новый месяц должен быть первым)
        sortedSections = groupedInvoices.keys.sorted { key1, key2 in
            guard let date1 = DateFormatter.monthYear.date(from: key1),
                  let date2 = DateFormatter.monthYear.date(from: key2) else {
                return false
            }
            return date1 > date2
        }
    }
    
    // MARK: - Data Fetching (ВОССТАНОВЛЕНО)
    
    private func fetchInvoices() -> [Invoice] {
        // Восстанавливаем оригинальную логику запроса к сервису
        let fetchedInvoices: [Invoice] = invoiceService?.getAllInvoices() ?? []
        
        // Сортировка по дате (новейшие в начале) перед группировкой
        return fetchedInvoices.sorted(by: { $0.creationDate > $1.creationDate })
    }
    
    private func deleteInvoice(invoice: Invoice) {
        do {
            try invoiceService?.deleteInvoice(id: invoice.id)
        } catch {
            print(error)
        }
    }
    
    // MARK: - Actions
    
    @objc func createInvoiceButtonTapped() {
        self.navigationController?.pushViewController(NewInvoiceViewController(), animated: true)
    }
    
    @objc func proBadgeTapped() {
        print("PRO Badge Tapped - Opening Paywall")
        let alert = UIAlertController(title: "Go PRO", message: "Unlock advanced features!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
extension InvoicesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionTitle = sortedSections[section]
        return groupedInvoices[sectionTitle]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .background
        
        let titleLabel = UILabel()
        titleLabel.text = sortedSections[section]
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .primaryText
        
        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(8)
        }
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InvoiceTableViewCell.reuseIdentifier, for: indexPath) as? InvoiceTableViewCell else {
            return UITableViewCell()
        }
        
        let sectionTitle = sortedSections[indexPath.section]
        if let invoice = groupedInvoices[sectionTitle]?[indexPath.row] {
            cell.configure(with: invoice)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionTitle = sortedSections[indexPath.section]
        if let selectedInvoice = groupedInvoices[sectionTitle]?[indexPath.row] {
            let invoiceDetailPDFVC = InvoiceDetailPDFViewController()
            invoiceDetailPDFVC.invoice = selectedInvoice
            self.navigationController?.pushViewController(invoiceDetailPDFVC, animated: true)
        }
    }
    
    // MARK: - Editing
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let sectionTitle = sortedSections[indexPath.section]
            guard let invoiceToDelete = groupedInvoices[sectionTitle]?[indexPath.row] else { return }
            
            // 1. Удаляем через service
            deleteInvoice(invoice: invoiceToDelete)
            
            // 2. Обновляем локальные данные (все счета)
            allInvoices.removeAll { $0.id == invoiceToDelete.id }
            
            // 3. Перезапускаем фильтрацию/группировку
            if let searchText = invoicesSearchBar.text, !searchText.isEmpty {
                 filteredInvoices = allInvoices.filter({ (invoice) -> Bool in
                    let titleMatch = invoice.invoiceTitle?.range(of: searchText, options: .caseInsensitive) != nil
                     let clientMatch = invoice.client?.clientName?.range(of: searchText, options: .caseInsensitive) != nil
                    return titleMatch || clientMatch
                })
            } else {
                filteredInvoices = allInvoices
            }
            // tableView.reloadData() вызовется через didSet
        }
    }
}

// MARK: - Search Bar Delegate
extension InvoicesViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredInvoices = allInvoices
        } else {
            filteredInvoices = allInvoices.filter({ (invoice) -> Bool in
                let titleMatch = invoice.invoiceTitle?.range(of: searchText, options: .caseInsensitive) != nil
                let clientMatch = invoice.client?.clientName?.range(of: searchText, options: .caseInsensitive) != nil
                return titleMatch || clientMatch
            })
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        filteredInvoices = allInvoices
    }
}
