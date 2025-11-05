import UIKit
import SnapKit

class BalanceReportViewController: UIViewController {
    
    // TODO: - Replace with actual data (Invoices total - Expenses total)
    private var mockIncomeTotal: Double = 33000.0 // Из Invoices Report
    private var mockExpenseTotal: Double = 2500.0 // Из Expenses Report
    private var mockBalance: Double { mockIncomeTotal - mockExpenseTotal }
    
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .background
        return sv
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    // MARK: - Balance Summary
    
    lazy var balanceTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Current Balance"
        label.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        label.textColor = .secondaryText
        label.textAlignment = .center
        return label
    }()
    
    lazy var balanceValueLabel: UILabel = {
        let label = UILabel()
        label.text = "$\(Int(mockBalance).formattedWithSeparator)"
        label.font = UIFont.systemFont(ofSize: 48, weight: .heavy)
        label.textColor = mockBalance >= 0 ? .success : .error // Динамический цвет
        label.textAlignment = .center
        return label
    }()
    
    lazy var balanceStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [balanceTitleLabel, balanceValueLabel])
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()
    
    // MARK: - Details Table
    
    lazy var detailsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .surface
        view.layer.cornerRadius = 12
        return view
    }()
    
    private func createDetailRow(title: String, value: Double, color: UIColor) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fill
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        titleLabel.textColor = .primaryText
        
        let valueLabel = UILabel()
        valueLabel.text = "$\(Int(value).formattedWithSeparator)"
        valueLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        valueLabel.textColor = color
        valueLabel.textAlignment = .right
        
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(valueLabel)
        
        titleLabel.snp.makeConstraints { $0.width.lessThanOrEqualTo(200) }
        
        return stack
    }
    
    lazy var incomeRow = createDetailRow(title: "Total Income", value: mockIncomeTotal, color: .primary)
    lazy var expensesRow = createDetailRow(title: "Total Expenses", value: mockExpenseTotal, color: .error)
    lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = .border
        view.snp.makeConstraints { $0.height.equalTo(1) }
        return view
    }()
    lazy var netBalanceRow = createDetailRow(title: "Net Balance", value: mockBalance, color: mockBalance >= 0 ? .success : .error)
    
    lazy var detailsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [incomeRow, expensesRow, separator, netBalanceRow])
        stack.axis = .vertical
        stack.spacing = 16
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        detailsContainer.addSubview(detailsStack)
        
        contentView.addSubview(balanceStackView)
        contentView.addSubview(detailsContainer)
        
        // Constraints
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        // Balance Stack
        balanceStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(50)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        // Details Container
        detailsContainer.snp.makeConstraints { make in
            make.top.equalTo(balanceStackView.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(20)
        }
        
        detailsStack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}
