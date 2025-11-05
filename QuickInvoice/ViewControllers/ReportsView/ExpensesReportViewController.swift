import UIKit
import SnapKit

class ExpensesReportViewController: UIViewController {
    
    // TODO: - Replace with actual data fetching logic
    private var mockExpenseData: [(category: String, amount: Double)] = [
        ("Software", 1200.0),
        ("Office Supplies", 350.0),
        ("Marketing", 800.0),
        ("Travel", 150.0)
    ]
    private var mockTotalExpenses: Double = 2500.0
    
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .background
        return sv
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    // MARK: - Expense Chart Elements
    
    lazy var chartViewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .surface
        view.layer.cornerRadius = 12
        return view
    }()
    
    lazy var chartTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Expense Breakdown"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .primaryText
        return label
    }()
    
    // TODO: - Pie Chart Visualization (Placeholder)
    lazy var pieChartPlaceholder: UILabel = {
        let label = UILabel()
        label.text = "TODO: Pie Chart of Expense Categories"
        label.textColor = .secondaryText
        label.textAlignment = .center
        label.numberOfLines = 2
        label.backgroundColor = .backgroundSecondary
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }()
    
    // MARK: - Summary Elements
    
    lazy var totalExpenseTile: UIView = {
        let view = UIView()
        view.backgroundColor = .surface
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        
        let titleLabel = UILabel()
        titleLabel.text = "Total Expenses"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .secondaryText
        
        let valueLabel = UILabel()
        valueLabel.text = "$\(Int(mockTotalExpenses).formattedWithSeparator)"
        valueLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        valueLabel.textColor = .error // Цвет для расходов
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 4
        
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        return view
    }()
    
    // MARK: - Expenses by Category Table
    
    lazy var detailsTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Expenses by Category"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .primaryText
        return label
    }()
    
    lazy var expenseTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .border
        tableView.backgroundColor = .surface
        tableView.rowHeight = 50
        tableView.layer.cornerRadius = 12
        tableView.isScrollEnabled = false
        return tableView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Chart Container Subviews
        chartViewContainer.addSubview(chartTitleLabel)
        chartViewContainer.addSubview(pieChartPlaceholder)
        
        // Add all components to contentView
        contentView.addSubview(chartViewContainer)
        contentView.addSubview(totalExpenseTile)
        contentView.addSubview(detailsTitleLabel)
        contentView.addSubview(expenseTableView)
        
        // Constraints
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        // Chart View Container
        chartViewContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(250)
        }
        
        chartTitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        
        pieChartPlaceholder.snp.makeConstraints { make in
            make.top.equalTo(chartTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
        }
        
        // Total Expense Tile
        totalExpenseTile.snp.makeConstraints { make in
            make.top.equalTo(chartViewContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(80)
        }
        
        // Expenses by Category
        detailsTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(totalExpenseTile.snp.bottom).offset(24)
            make.leading.equalToSuperview().inset(20)
        }
        
        // Table View (dynamic height based on content)
        let tableHeight = CGFloat(mockExpenseData.count) * expenseTableView.rowHeight
        expenseTableView.snp.makeConstraints { make in
            make.top.equalTo(detailsTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(tableHeight)
            make.bottom.equalToSuperview().inset(20) // Конец контента
        }
    }
    
    private func setupTableView() {
        expenseTableView.delegate = self
        expenseTableView.dataSource = self
        expenseTableView.register(ExpenseCell.self, forCellReuseIdentifier: ExpenseCell.reuseIdentifier)
    }
}

// MARK: - Table View Delegate & Data Source
extension ExpensesReportViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mockExpenseData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ExpenseCell.reuseIdentifier, for: indexPath) as? ExpenseCell else {
            return UITableViewCell()
        }
        
        let data = mockExpenseData[indexPath.row]
        cell.configure(category: data.category, amount: data.amount)
        cell.backgroundColor = .surface
        cell.selectionStyle = .none
        
        return cell
    }
}

// MARK: - Expense Table Cell
private class ExpenseCell: UITableViewCell {
    
    static let reuseIdentifier = "ExpenseCell"
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .primaryText
        return label
    }()
    
    private let amountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .error
        label.textAlignment = .right
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(amountLabel)
        
        categoryLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        amountLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(category: String, amount: Double) {
        categoryLabel.text = category
        amountLabel.text = "-$\(Int(amount).formattedWithSeparator)"
    }
}
