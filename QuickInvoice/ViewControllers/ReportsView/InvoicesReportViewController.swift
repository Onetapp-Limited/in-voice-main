import UIKit
import SnapKit

class InvoicesReportViewController: UIViewController {
    
    // TODO: - Replace with actual data fetching logic
    private var mockMonthlyData: [Double] = [5000, 7500, 12000, 15000, 10500, 18000] // Доходы по месяцам
    private var mockSummary = (paid: 25000.0, unpaid: 8000.0, total: 33000.0)
    private var mockClientSales: [(client: String, earned: Double, paid: Double)] = [
        ("Tech Innovators Co.", 15000.0, 10000.0),
        ("Global Dynamics Inc.", 8000.0, 8000.0),
        ("Sunrise Marketing Agency", 10000.0, 7000.0)
    ]
    
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .background
        return sv
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    // MARK: - Chart Elements
    
    lazy var chartViewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .surface
        view.layer.cornerRadius = 12
        return view
    }()
    
    lazy var chartTypeSegmentedControl: UISegmentedControl = {
        let items = ["Line Chart", "Table View"]
        let segmented = UISegmentedControl(items: items)
        // Наследуем стиль
        segmented.selectedSegmentTintColor = UIColor.primaryLight
        segmented.backgroundColor = UIColor.backgroundSecondary
        
        let font = UIFont.systemFont(ofSize: 13, weight: .medium)
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.primaryText,
            .font: font
        ]
        segmented.setTitleTextAttributes(selectedAttributes, for: .selected)
        segmented.setTitleTextAttributes([.font: font], for: .normal)
        
        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(toggleChartType), for: .valueChanged)
        return segmented
    }()
    
    // TODO: - Chart Visualization (Placeholder)
    lazy var lineChartPlaceholder: UILabel = {
        let label = UILabel()
        label.text = "TODO: Line Chart (Y: Income, X: Months)"
        label.textColor = .secondaryText
        label.textAlignment = .center
        label.numberOfLines = 2
        label.backgroundColor = .backgroundSecondary
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }()
    
    lazy var chartTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Monthly Income"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .primaryText
        return label
    }()
    
    // MARK: - Summary Elements
    
    lazy var summaryStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16
        return stack
    }()
    
    // Utility for Summary Tiles
    private func createSummaryTile(title: String, value: Double, color: UIColor) -> UIView {
        let view = UIView()
        view.backgroundColor = .surface
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryText
        
        let valueLabel = UILabel()
        valueLabel.text = "$\(Int(value).formattedWithSeparator)" // Предполагаем формат
        valueLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        valueLabel.textColor = color
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 4
        
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        
        return view
    }
    
    // MARK: - Sales By Client Table
    
    lazy var salesTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Sales by Client"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .primaryText
        return label
    }()
    
    lazy var salesTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .border
        tableView.backgroundColor = .surface
        tableView.rowHeight = 50
        tableView.layer.cornerRadius = 12
        tableView.isScrollEnabled = false // Внутри ScrollView не скроллим
        return tableView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        updateSummary()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Setup Summary Tiles
        let paidTile = createSummaryTile(title: "Paid", value: mockSummary.paid, color: .success)
        let unpaidTile = createSummaryTile(title: "Unpaid", value: mockSummary.unpaid, color: .warning)
        let totalTile = createSummaryTile(title: "Total", value: mockSummary.total, color: .primary)
        summaryStackView.addArrangedSubview(paidTile)
        summaryStackView.addArrangedSubview(unpaidTile)
        summaryStackView.addArrangedSubview(totalTile)
        
        // Chart Container Subviews
        chartViewContainer.addSubview(chartTitleLabel)
        chartViewContainer.addSubview(chartTypeSegmentedControl)
        chartViewContainer.addSubview(lineChartPlaceholder)
        
        // Add all components to contentView
        contentView.addSubview(chartViewContainer)
        contentView.addSubview(summaryStackView)
        contentView.addSubview(salesTitleLabel)
        contentView.addSubview(salesTableView)
        
        // Constraints
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview() // Важно для скролла
        }
        
        // Chart View Container
        chartViewContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(300)
        }
        
        chartTitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        
        chartTypeSegmentedControl.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(chartTitleLabel)
            make.width.equalTo(180)
        }
        
        lineChartPlaceholder.snp.makeConstraints { make in
            make.top.equalTo(chartTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
        }
        
        // Summary Stack View
        summaryStackView.snp.makeConstraints { make in
            make.top.equalTo(chartViewContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        // Sales By Client
        salesTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(summaryStackView.snp.bottom).offset(24)
            make.leading.equalToSuperview().inset(20)
        }
        
        // Table View (dynamic height based on content)
        let tableHeight = CGFloat(mockClientSales.count) * salesTableView.rowHeight
        salesTableView.snp.makeConstraints { make in
            make.top.equalTo(salesTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(tableHeight)
            make.bottom.equalToSuperview().inset(20) // Конец контента
        }
    }
    
    private func setupTableView() {
        salesTableView.delegate = self
        salesTableView.dataSource = self
        salesTableView.register(ClientSalesCell.self, forCellReuseIdentifier: ClientSalesCell.reuseIdentifier)
    }
    
    // MARK: - Data Logic
    
    private func updateSummary() {
        // TODO: Update summary tiles with live data
    }
    
    // MARK: - Actions
    
    @objc private func toggleChartType(_ sender: UISegmentedControl) {
        let isLineChart = sender.selectedSegmentIndex == 0
        lineChartPlaceholder.text = isLineChart ? "TODO: Line Chart (Y: Income, X: Months)" : "TODO: Table View of Monthly Income"
    }
}

// MARK: - Table View Delegate & Data Source
extension InvoicesReportViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mockClientSales.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ClientSalesCell.reuseIdentifier, for: indexPath) as? ClientSalesCell else {
            return UITableViewCell()
        }
        
        let data = mockClientSales[indexPath.row]
        cell.configure(clientName: data.client, earned: data.earned, paid: data.paid)
        
        // Стиль ячейки
        cell.backgroundColor = .surface
        cell.selectionStyle = .none
        
        return cell
    }
}

// MARK: - Client Sales Table Cell
private class ClientSalesCell: UITableViewCell {
    
    static let reuseIdentifier = "ClientSalesCell"
    
    private let clientLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .primaryText
        return label
    }()
    
    private let earnedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryText
        label.textAlignment = .right
        return label
    }()
    
    private let paidStatusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        label.textAlignment = .right
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(clientLabel)
        contentView.addSubview(earnedLabel)
        contentView.addSubview(paidStatusLabel)
        
        clientLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        paidStatusLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(70)
        }
        
        earnedLabel.snp.makeConstraints { make in
            make.trailing.equalTo(paidStatusLabel.snp.leading).offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(clientName: String, earned: Double, paid: Double) {
        clientLabel.text = clientName
        earnedLabel.text = "Earned: $\(Int(earned).formattedWithSeparator)"
        
        let unpaid = earned - paid
        if unpaid <= 0.0 {
            paidStatusLabel.text = "Paid"
            paidStatusLabel.textColor = .success
        } else {
            paidStatusLabel.text = "Unpaid"
            paidStatusLabel.textColor = .warning
        }
    }
}

// MARK: - Utility Extension (for formatting)
// Восстанавливаем функцию форматирования, если ее нет в коде
extension Int {
    var formattedWithSeparator: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = ","
        return numberFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
