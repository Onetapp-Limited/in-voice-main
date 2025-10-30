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
    
    // MARK: - UI Elements (Соответствуют стилю InvoicesViewController)
    
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
        // NOTE: Используем GradientButton по аналогии с InvoicesViewController
        let button = GradientButton(type: .custom)
        button.setTitle("Create New Estimate", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        // NOTE: Системная иконка "plus" используется для визуального стиля (как у вас)
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
        // Обновляем данные при каждом появлении
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
        titleLabel.text = "Estimates" // Изменено на "Estimates"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = UIColor.primaryText // Ваш кастомный цвет
        
        let leftStack = UIStackView(arrangedSubviews: [UIView(), logoImageView, titleLabel, UIView()])
        leftStack.axis = .horizontal
        leftStack.spacing = 8
        
        let leftBarItem = UIBarButtonItem(customView: leftStack)
        navigationItem.leftBarButtonItem = leftBarItem
        
        // 2. Правый элемент: PRO Badge (по аналогии)
        let proButton = UIButton(type: .custom)
        proButton.setTitle("PRO", for: .normal)
        proButton.setTitleColor(.white, for: .normal)
        proButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .heavy)
        
        let starIcon = UIImage(systemName: "crown.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold))
        proButton.setImage(starIcon, for: .normal)
        proButton.tintColor = .white
        
        // NOTE: Используем кастомный цвет для PRO Badge (если нет своего 'gold', используем 'accent' или определенный UIColor)
        // В вашем примере использовался RGB. Если в вашем Asset Catalog есть цвет "Gold", используйте его.
        // Здесь оставлен ваш оригинальный цвет для PRO Badge.
        proButton.backgroundColor = UIColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1.0)
        proButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        proButton.layer.cornerRadius = 10
        proButton.clipsToBounds = true
        
        proButton.addTarget(self, action: #selector(proBadgeTapped), for: .touchUpInside)
        
        let rightBarItem = UIBarButtonItem(customView: proButton)
        navigationItem.rightBarButtonItem = rightBarItem
        
        // 3. Общие настройки Navigation Bar (по аналогии)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.background // Ваш кастомный цвет
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.isTranslucent = false
    }
    
    func setupUI() {
        
        view.addSubview(estimatesSearchBar)
        view.addSubview(estimatesTableView)
        view.addSubview(createEstimateButton)
        
        // Констрейнты для Search Bar
        estimatesSearchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        
        // Констрейнты для Кнопки (снизу)
        createEstimateButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(24)
            make.height.equalTo(50)
        }
        
        // Констрейнты для TableView (заканчивается над кнопкой)
        estimatesTableView.snp.makeConstraints { make in
            make.top.equalTo(estimatesSearchBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(createEstimateButton.snp.top).offset(-16)
        }
    }
    
    func setup() {
        estimatesTableView.delegate = self
        estimatesTableView.dataSource = self
        
        estimatesSearchBar.delegate = self
        
        // NOTE: Регистрация новой ячейки
        estimatesTableView.register(EstimateTableViewCell.self, forCellReuseIdentifier: EstimateTableViewCell.reuseIdentifier)
    }
    
    // MARK: - Data Logic (Grouping)
    
    private func groupEstimatesByMonth(_ estimates: [Estimate]) {
        groupedEstimates = Dictionary(grouping: estimates) { estimate -> String in
            // Группируем по месяцу и году создания
            // NOTE: Предполагается, что DateFormatter.monthYear доступен
            return DateFormatter.monthYear.string(from: estimate.creationDate)
        }
        
        // Сортируем ключи (секции) по дате (самый новый месяц должен быть первым)
        sortedSections = groupedEstimates.keys.sorted { key1, key2 in
            // NOTE: Предполагается, что DateFormatter.monthYear доступен
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
extension EstimatesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionTitle = sortedSections[section]
        return groupedEstimates[sectionTitle]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.background // Ваш кастомный цвет
        
        let titleLabel = UILabel()
        titleLabel.text = sortedSections[section]
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = UIColor.primaryText // Ваш кастомный цвет
        
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
            // NOTE: Замените на ваш EstimateDetailViewController
            // let detailVC = EstimateDetailPDFViewController()
            // detailVC.estimate = selectedEstimate
            // self.navigationController?.pushViewController(detailVC, animated: true)
            print("Selected Estimate: \(selectedEstimate.estimateTitle ?? "")")
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
            if let searchText = estimatesSearchBar.text, !searchText.isEmpty {
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
