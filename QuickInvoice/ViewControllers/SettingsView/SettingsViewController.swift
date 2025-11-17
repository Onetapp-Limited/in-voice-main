import UIKit
import SnapKit
import StoreKit

enum Links {
    static let termsOfServiceURL = "https://docs.google.com/document/d/1HGXHDYjPD3TvXkYv23HXHesmR50mGKTW32byUy6CrjI/edit?usp=sharing"
    static let privacyPolicyURL = "https://docs.google.com/document/d/106Fiz2-_vg4O09vDIsir-yW5LyKId5yMU7JSOAzetms/edit?usp=sharing"
    static let contactUsEmail = "onetapp@icloud.com"
    static let supportEmailSubject = "Invoice Support Request"
}

class SettingsViewController: UIViewController {

    enum Constants {

        enum Settings {
            static let screenTitle = "Settings"
            static let supportSectionTitle = "Legal & Support"
            static let actionsSectionTitle = "App Actions"
            
            static let emailAlertTitle = "Email Client Not Setup"
            static let emailAlertMessage = "Please contact us manually at \(Links.contactUsEmail)"
        }
    }
    
    // MARK: - Settings Data Model
    
    // Перечисление для определения структуры экрана (секции и строки)
    enum SettingsSection: Int, CaseIterable {
        case support
        case actions
        
        var title: String {
            switch self {
            case .support: return Constants.Settings.supportSectionTitle
            case .actions: return Constants.Settings.actionsSectionTitle
            }
        }
        
        var items: [SettingsItem] {
            switch self {
            case .support:
                return [.privacy, .terms, .contactUs]
            case .actions:
                return [.rateUs]
            }
        }
    }
    
    enum SettingsItem {
        case privacy
        case terms
        case contactUs
        case rateUs
        
        var title: String {
            switch self {
            case .privacy: return "Privacy Policy"
            case .terms: return "Terms of Service"
            case .contactUs: return "Contact Us"
            case .rateUs: return "Rate Us"
            }
        }
    }

    // MARK: - UI Elements
    
    private lazy var settingsTableView: UITableView = {
        // Используем .insetGrouped для автоматического добавления отступов для секций
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SettingsCell.self, forCellReuseIdentifier: SettingsCell.reuseIdentifier)
        tableView.backgroundColor = UIColor.background
        // Отключаем стандартный разделитель, т.к. ячейки будут "карточками"
        tableView.separatorStyle = .none
        tableView.rowHeight = 60
        // Устанавливаем padding сверху, чтобы таблица не была приклеена к NavigationBar
        tableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0)
        return tableView
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.background
        setupNavigationBar()
        setupUI()
    }
    
    // MARK: - Setup

    private func setupNavigationBar() {
        
        // 1. Левый элемент: Иконка + Title "InvoiceFly"
        let logoImage = UIImage(systemName: "gearshape.fill")?.withTintColor(.accent, renderingMode: .alwaysOriginal)
        let logoImageView = UIImageView(image: logoImage)
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.snp.makeConstraints { make in make.size.equalTo(24) }
        
        let titleLabel = UILabel()
        titleLabel.text = "Settings"
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
        //        navigationItem.rightBarButtonItem = rightBarItem // test111

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
        view.addSubview(settingsTableView)
        
        settingsTableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    // MARK: - Actions
    
    private func handleSelection(item: SettingsItem) {
        switch item {
        case .privacy:
            openExternalURL(string: Links.privacyPolicyURL)
        case .terms:
            openExternalURL(string: Links.termsOfServiceURL)
        case .contactUs:
            openEmailClient(email: Links.contactUsEmail)
        case .rateUs:
            requestAppStoreReview()
        }
    }
    
    // MARK: - System Handlers
    
    private func openExternalURL(string: String) {
        guard let url = URL(string: string) else {
            print("SettingsViewController: Invalid URL string: \(string)")
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    private func openEmailClient(email: String) {
        let mailtoUrlString = "mailto:\(email)?subject=\(Links.supportEmailSubject)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        guard let url = URL(string: mailtoUrlString),
              UIApplication.shared.canOpenURL(url) else {
            print("SettingsViewController: Cannot open email client or invalid mailto URL.")
            // Показываем UIAlertController, т.к. alert() запрещен
            self.showEmailNotConfiguredAlert(email: email)
            return
        }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    private func requestAppStoreReview() {
        // Используем SKStoreReviewController для запроса оценки
        if #available(iOS 14.0, *) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
    }
    
    private func showEmailNotConfiguredAlert(email: String) {
        let alert = UIAlertController(
            title: Constants.Settings.emailAlertTitle,
            message: Constants.Settings.emailAlertMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc func proBadgeTapped() {
        let paywallVC = PaywallViewController()
        let navController = UINavigationController(rootViewController: paywallVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
}

// MARK: - Table View Delegate and Data Source
extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return SettingsSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SettingsSection.allCases[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingsCell.reuseIdentifier, for: indexPath) as? SettingsCell else {
            return UITableViewCell()
        }
        
        let section = SettingsSection.allCases[indexPath.section]
        let item = section.items[indexPath.row]
        
        cell.configure(with: item.title)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let section = SettingsSection.allCases[indexPath.section]
        let item = section.items[indexPath.row]
        
        handleSelection(item: item)
    }
    
    // Настраиваем заголовки секций, чтобы они соответствовали стилю
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return SettingsSection.allCases[section].title
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = UIColor.secondaryText
            header.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        }
    }
}
