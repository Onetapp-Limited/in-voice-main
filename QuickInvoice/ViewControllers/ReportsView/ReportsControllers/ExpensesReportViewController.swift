import UIKit
import SnapKit

class ExpensesReportViewController: UIViewController {
    
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
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        return sv
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var totalExpenseCard: UIView = {
        let container = UIView()
        container.backgroundColor = .surface
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.08
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 8
        
        let titleLabel = UILabel()
        titleLabel.text = "Total Expenses"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .secondaryText
        
        let valueLabel = UILabel()
        valueLabel.text = "$\(Int(mockTotalExpenses).formattedWithSeparator)"
        valueLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        valueLabel.textColor = .error
        
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(20)
        }
        
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        return container
    }()
    
    private lazy var chartContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .surface
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        return view
    }()
    
    private lazy var chartTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Expense Breakdown"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .primaryText
        return label
    }()
    
    private lazy var pieChartPlaceholder: UILabel = {
        let label = UILabel()
        label.text = "🥧\n\nPie Chart\nExpense Categories"
        label.textColor = .secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.backgroundColor = .backgroundSecondary
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }()
    
    private lazy var expensesTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Expenses by Category"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .primaryText
        return label
    }()
    
    private lazy var expensesTableContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .surface
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        return view
    }()
    
    private lazy var expenseTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.separatorStyle = .singleLine
        table.separatorColor = .border
        table.backgroundColor = .clear
        table.rowHeight = 60
        table.isScrollEnabled = false
        table.layer.cornerRadius = 12
        table.clipsToBounds = true
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        setupTableView()
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        chartContainer.addSubview(chartTitleLabel)
        chartContainer.addSubview(pieChartPlaceholder)
        
        expensesTableContainer.addSubview(expenseTableView)
        
        contentView.addSubview(totalExpenseCard)
        contentView.addSubview(chartContainer)
        contentView.addSubview(expensesTitleLabel)
        contentView.addSubview(expensesTableContainer)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }
        
        totalExpenseCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        chartContainer.snp.makeConstraints { make in
            make.top.equalTo(totalExpenseCard.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(240)
        }
        
        chartTitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }
        
        pieChartPlaceholder.snp.makeConstraints { make in
            make.top.equalTo(chartTitleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        expensesTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(chartContainer.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(20)
        }
        
        expensesTableContainer.snp.makeConstraints { make in
            make.top.equalTo(expensesTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(CGFloat(mockExpenseData.count * 60))
            make.bottom.equalToSuperview().offset(-20)
        }
        
        expenseTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupTableView() {
        expenseTableView.delegate = self
        expenseTableView.dataSource = self
        expenseTableView.register(ExpenseCell.self, forCellReuseIdentifier: ExpenseCell.reuseIdentifier)
    }
}

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
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        return cell
    }
}
