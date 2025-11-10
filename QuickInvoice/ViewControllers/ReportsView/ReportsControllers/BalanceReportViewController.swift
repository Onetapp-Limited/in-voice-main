import UIKit
import SnapKit

class BalanceReportViewController: UIViewController {
    
    private var invoiceService: InvoiceService? {
        do {
            return try InvoiceService()
        } catch {
            print("Failed to initialize InvoiceService: \(error)")
            return nil
        }
    }
    
    // 🔑 2. Хранение реальных данных
    private var totalIncome: Double = 0.0
    private var totalExpenses: Double = 0.0
    private var netBalance: Double { totalIncome - totalExpenses }

    private func parseTotalAmount(_ value: String) -> Double {
        let cleaned = value
            .replacingOccurrences(of: "[^0-9.,-]", with: "", options: .regularExpression)
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned) ?? 0
    }
    
    // MARK: - Data Calculation

    private func calculateTotalIncome() -> Double {
        guard let invoices = invoiceService?.getAllInvoices() else {
            return 0.0
        }
        let total = invoices.reduce(0) { $0 + parseTotalAmount($1.totalAmount) }
        return total
    }

    private func calculateTotalExpenses() -> Double {
        guard let invoices = invoiceService?.getAllInvoices() else {
            return 0.0
        }
        let totalExpense = invoices.reduce(0) { $0 + $1.taxTotal }
        return totalExpense
    }

    // MARK: - UI Components (Обновляем lazy var для использования реальных данных через функцию)
    
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .background
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        return sv
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var balanceCard: UIView = {
        let container = UIView()
        container.backgroundColor = .surface
        container.layer.cornerRadius = 16
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.1
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
        container.layer.shadowRadius = 12
        
        let titleLabel = UILabel()
        titleLabel.text = "Current Net Balance"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .secondaryText
        titleLabel.textAlignment = .center
        
        let valueLabel = UILabel()
        valueLabel.tag = 101 // Устанавливаем тэг для быстрого обновления
        valueLabel.text = "$\(Int(self.netBalance).formattedWithSeparator)" // Используем netBalance
        valueLabel.font = UIFont.systemFont(ofSize: 48, weight: .heavy)
        valueLabel.textColor = self.netBalance >= 0 ? .systemGreen : .systemRed
        valueLabel.textAlignment = .center
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7
        
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-30)
        }
        
        return container
    }()
    
    private lazy var detailsCard: UIView = {
        let container = UIView()
        container.backgroundColor = .surface
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.08
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 8
        return container
    }()
    
    private func createDetailRow(title: String, value: Double, color: UIColor, tag: Int) -> UIView {
        let container = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .primaryText
        
        let valueLabel = UILabel()
        valueLabel.tag = tag // Устанавливаем тэг для обновления
        valueLabel.text = "$\(Int(value).formattedWithSeparator)"
        valueLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        valueLabel.textColor = color
        valueLabel.textAlignment = .right
        
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        
        valueLabel.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(16)
        }
        
        return container
    }
    
    // Обновляем инициализацию с тэгами
    private lazy var incomeRow = createDetailRow(title: "Total Income", value: 0, color: .primary, tag: 102)
    private lazy var expensesRow = createDetailRow(title: "Total Expenses (VAT/Tax)", value: 0, color: .error, tag: 103)
    
    private lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = .border
        return view
    }()
    
    private lazy var netBalanceRow = createDetailRow(title: "Net Balance", value: 0, color: netBalance >= 0 ? .success : .error, tag: 104)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        // Сначала настраиваем UI
        setupUI()
        // Затем загружаем и отображаем данные
        updateDataAndUI()
    }
    
    // 🔑 5. Функция для загрузки данных и обновления UI
    private func updateDataAndUI() {
        // 1. Загрузка данных
        self.totalIncome = calculateTotalIncome()
        self.totalExpenses = calculateTotalExpenses()
        
        let currentBalance = self.netBalance
        let balanceColor: UIColor = currentBalance >= 0 ? .systemGreen : .systemRed
        
        // 2. Обновление UI-элементов по тегам
        
        // Обновление Главной Карточки (BalanceCard)
        if let balanceValueLabel = balanceCard.viewWithTag(101) as? UILabel {
            balanceValueLabel.text = "$\(Int(currentBalance).formattedWithSeparator)"
            balanceValueLabel.textColor = balanceColor
        }
        
        // Обновление Total Income Row
        if let incomeValueLabel = incomeRow.viewWithTag(102) as? UILabel {
            incomeValueLabel.text = "$\(Int(self.totalIncome).formattedWithSeparator)"
        }
        
        // Обновление Total Expenses Row
        if let expensesValueLabel = expensesRow.viewWithTag(103) as? UILabel {
            expensesValueLabel.text = "$\(Int(self.totalExpenses).formattedWithSeparator)"
        }
        
        // Обновление Net Balance Row
        if let netBalanceValueLabel = netBalanceRow.viewWithTag(104) as? UILabel {
            netBalanceValueLabel.text = "$\(Int(currentBalance).formattedWithSeparator)"
            netBalanceValueLabel.textColor = balanceColor
        }
    }
    
    // MARK: - UI Setup (Без изменений)
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        detailsCard.addSubview(incomeRow)
        detailsCard.addSubview(expensesRow)
        detailsCard.addSubview(separator)
        detailsCard.addSubview(netBalanceRow)
        
        contentView.addSubview(balanceCard)
        contentView.addSubview(detailsCard)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }
        
        balanceCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        detailsCard.snp.makeConstraints { make in
            make.top.equalTo(balanceCard.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        incomeRow.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(30)
        }
        
        expensesRow.snp.makeConstraints { make in
            make.top.equalTo(incomeRow.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(30)
        }
        
        separator.snp.makeConstraints { make in
            make.top.equalTo(expensesRow.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(1)
        }
        
        netBalanceRow.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(30)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
}
