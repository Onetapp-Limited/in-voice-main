import UIKit
import SnapKit

class EstimatesViewController: UIViewController {
    
    // MARK: - Data Grouping Properties
    private var groupedEstimates: [String: [Estimate]] = [:]
    private var sortedSections: [String] = []
    
    private var allEstimates: [Estimate] = []
    
    var filteredEstimates: [Estimate] = [] {
        didSet {
            groupEstimatesByMonth(filteredEstimates)
            estimatesTableView.reloadData()
        }
    }
    
    private var estimateService: EstimateService? {
        do {
            return try EstimateService()
        } catch {
            print("Failed to initialize EstimateService: \(error)")
            return nil
        }
    }
    
    // MARK: - UI Elements
    
    // ⭐ НОВОЕ: Баннер для основной информации
    private lazy var infoBannerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.secondary // Ваш кастомный secondary цвет
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    // ⭐ НОВОЕ: Заголовок баннера
    private lazy var bannerTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Manage Estimates" // Грамотный тайтл
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    // ⭐ НОВОЕ: Подзаголовок баннера
    private lazy var bannerSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create and track your estimates, convert them to invoices later." // Грамотный сабтайтл
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.8)
        label.numberOfLines = 0
        return label
    }()
    
    lazy var estimatesTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.background // Ваш кастомный цвет
        tableView.rowHeight = 85
        return tableView
    }()
    
    lazy var estimatesSearchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search Estimates"
        searchBar.barTintColor = UIColor.background // Ваш кастомный цвет
        searchBar.searchBarStyle = .minimal
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor.surface // Ваш кастомный цвет
            textField.textColor = UIColor.primaryText // Ваш кастомный цвет
            textField.layer.cornerRadius = 10
            textField.clipsToBounds = true
        }
        return searchBar
    }()
    
    lazy var createEstimateButton: GradientButton = {
        let button = GradientButton(type: .custom)
        button.setTitle("Create New Estimate", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        let plusConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let plusImage = UIImage(systemName: "plus", withConfiguration: plusConfig)?
            .withRenderingMode(.alwaysTemplate)
        button.setImage(plusImage, for: .normal)
        button.tintColor = .white
        
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: -10)
        
        button.addTarget(self, action: #selector(createEstimateButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.background // Ваш кастомный цвет
        setupNavigationBar()
        setupUI()
        setup()
        setupTapToDismissKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        allEstimates = fetchEstimates()
        filteredEstimates = allEstimates
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        
        // 1. Левый элемент: Иконка + Title "InvoiceFly" (по аналогии)
        // NOTE: Заменил иконку на "dollarsign.square.fill", более подходящую для Estimates
        let logoImage = UIImage(systemName: "dollarsign.square.fill")?.withTintColor(UIColor.accent, renderingMode: .alwaysOriginal) // Ваш кастомный цвет
        let logoImageView = UIImageView(image: logoImage)
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.snp.makeConstraints { make in make.size.equalTo(24) }
        
        let titleLabel = UILabel()
        titleLabel.text = "Estimates"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = UIColor.primaryText
        
        let leftStack = UIStackView(arrangedSubviews: [UIView(), logoImageView, titleLabel, UIView()])
        leftStack.axis = .horizontal
        leftStack.spacing = 8
        
        let leftBarItem = UIBarButtonItem(customView: leftStack)
        navigationItem.leftBarButtonItem = leftBarItem
        
        // 2. Правый элемент
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
        
        // 3. Общие настройки
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.background
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.isTranslucent = false
    }
    
    func setupUI() {
        
        view.addSubview(estimatesSearchBar)
        
        // ⭐ НОВОЕ: Добавляем баннер
        view.addSubview(infoBannerView)
        infoBannerView.addSubview(bannerTitleLabel)
        infoBannerView.addSubview(bannerSubtitleLabel)

        view.addSubview(estimatesTableView)
        view.addSubview(createEstimateButton)
        
        // Констрейнты для Search Bar
        estimatesSearchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        
        // ⭐ НОВОЕ: Констрейнты для баннера (под Search Bar)
        infoBannerView.snp.makeConstraints { make in
            make.top.equalTo(estimatesSearchBar.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        bannerTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        bannerSubtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(bannerTitleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        // Констрейнты для Кнопки (снизу)
        createEstimateButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(24)
            make.height.equalTo(50)
        }
        
        // Констрейнты для TableView (начинается под баннером и заканчивается над кнопкой)
        estimatesTableView.snp.makeConstraints { make in
            make.top.equalTo(infoBannerView.snp.bottom).offset(16) // Смещение после баннера
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(createEstimateButton.snp.top).offset(-16)
        }
    }
    
    func setup() {
        estimatesTableView.delegate = self
        estimatesTableView.dataSource = self
        
        estimatesSearchBar.delegate = self
        
        estimatesTableView.register(EstimateTableViewCell.self, forCellReuseIdentifier: EstimateTableViewCell.reuseIdentifier)
    }
    
    // MARK: - Data Logic (Grouping)
    
    private func groupEstimatesByMonth(_ estimates: [Estimate]) {
        groupedEstimates = Dictionary(grouping: estimates) { estimate -> String in
            // Группируем по месяцу и году создания
            return DateFormatter.monthYear.string(from: estimate.creationDate)
        }
        
        // Сортируем ключи (секции) по дате (самый новый месяц должен быть первым)
        sortedSections = groupedEstimates.keys.sorted { key1, key2 in
            guard let date1 = DateFormatter.monthYear.date(from: key1),
                  let date2 = DateFormatter.monthYear.date(from: key2) else {
                return false
            }
            return date1 > date2
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchEstimates() -> [Estimate] {
        let fetchedEstimates: [Estimate] = estimateService?.getAllEstimates() ?? []
        return fetchedEstimates.sorted(by: { $0.creationDate > $1.creationDate })
    }
    
    private func deleteEstimate(estimate: Estimate) {
        do {
            try estimateService?.deleteEstimate(id: estimate.id)
        } catch {
            print(error)
        }
    }
    
    // MARK: - Actions
    
    @objc func createEstimateButtonTapped() {
        navigationController?.pushViewController(NewEstimateViewController(), animated: true)
    }
    
    @objc func proBadgeTapped() {
        let paywallVC = PaywallViewController()
        let navController = UINavigationController(rootViewController: paywallVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
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
extension EstimatesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionTitle = sortedSections[section]
        return groupedEstimates[sectionTitle]?.count ?? 0
    }
    
    // ⭐ ОБНОВЛЕНО: Добавлен расчет суммы и отображение в заголовке
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.background
        
        let sectionTitle = sortedSections[section]
        
        // Расчет общей суммы для секции
        let totalAmount = groupedEstimates[sectionTitle]?.reduce(0.0) { $0 + $1.grandTotal } ?? 0.0
        // Используем валюту первой сметы в секции для отображения символа
        let currencySymbol = groupedEstimates[sectionTitle]?.first?.currencySymbol ?? "$"
        
        // 1. Лейбл с месяцем
        let monthLabel = UILabel()
        monthLabel.text = sectionTitle
        monthLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        monthLabel.textColor = UIColor.primaryText
        
        // 2. Лейбл с суммой
        let totalLabel = UILabel()
        let formattedTotal = String(format: "%.2f", totalAmount)
        totalLabel.text = "\(currencySymbol)\(formattedTotal) Total Estimated" // Короткое пояснение
        totalLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        totalLabel.textColor = UIColor.secondaryText // Более приглушенный цвет
        totalLabel.textAlignment = .right
        
        // Стек для размещения заголовка и суммы
        let stackView = UIStackView(arrangedSubviews: [monthLabel, totalLabel])
        stackView.axis = .horizontal
        stackView.alignment = .bottom
        stackView.spacing = 10
        
        headerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().inset(8)
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EstimateTableViewCell.reuseIdentifier, for: indexPath) as? EstimateTableViewCell else {
            return UITableViewCell()
        }
        
        let sectionTitle = sortedSections[indexPath.section]
        if let estimate = groupedEstimates[sectionTitle]?[indexPath.row] {
            cell.configure(with: estimate)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionTitle = sortedSections[indexPath.section]
        if let selectedEstimate = groupedEstimates[sectionTitle]?[indexPath.row] {
            let invoiceDetailPDFVC = InvoiceDetailPDFViewController()
            invoiceDetailPDFVC.invoice = mapEstimateToInvoice(selectedEstimate)
            invoiceDetailPDFVC.isEstimate = true
            self.navigationController?.pushViewController(invoiceDetailPDFVC, animated: true)
        }
    }
    
    // MARK: - Editing
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let sectionTitle = sortedSections[indexPath.section]
            guard let estimateToDelete = groupedEstimates[sectionTitle]?[indexPath.row] else { return }
            
            // 1. Удаляем через service
            deleteEstimate(estimate: estimateToDelete)
            
            // 2. Обновляем локальные данные (все оценки)
            allEstimates.removeAll { $0.id == estimateToDelete.id }
            
            // 3. Перезапускаем фильтрацию/группировку
            let searchText = estimatesSearchBar.text ?? ""
            if !searchText.isEmpty {
                filteredEstimates = allEstimates.filter({ (estimate) -> Bool in
                    let titleMatch = estimate.estimateTitle?.range(of: searchText, options: .caseInsensitive) != nil
                    let clientMatch = estimate.client?.clientName?.range(of: searchText, options: .caseInsensitive) != nil
                    return titleMatch || clientMatch
                })
            } else {
                filteredEstimates = allEstimates
            }
            // tableView.reloadData() вызовется через didSet
        }
    }
    
    func mapEstimateToInvoice(_ estimate: Estimate) -> Invoice {
        return Invoice(
            id: estimate.id,
            invoiceTitle: estimate.estimateTitle,
            client: estimate.client,
            items: estimate.items,
            taxRate: estimate.taxRate,
            discount: estimate.discount,
            discountType: estimate.discountType,
            creationDate: estimate.creationDate,
            status: estimate.status,
            currency: estimate.currency,
            totalAmount: estimate.totalAmount
        )
    }
}

// MARK: - Search Bar Delegate
extension EstimatesViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredEstimates = allEstimates
        } else {
            filteredEstimates = allEstimates.filter({ (estimate) -> Bool in
                let titleMatch = estimate.estimateTitle?.range(of: searchText, options: .caseInsensitive) != nil
                let clientMatch = estimate.client?.clientName?.range(of: searchText, options: .caseInsensitive) != nil
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
        filteredEstimates = allEstimates
    }
}
