import UIKit
import SnapKit

class BalanceReportViewController: UIViewController {
    
    private var mockIncomeTotal: Double = 33000.0
    private var mockExpenseTotal: Double = 2500.0
    private var mockBalance: Double { mockIncomeTotal - mockExpenseTotal }
    
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
        titleLabel.text = "Current Balance"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .secondaryText
        titleLabel.textAlignment = .center
        
        let valueLabel = UILabel()
        valueLabel.text = "$\(Int(mockBalance).formattedWithSeparator)"
        valueLabel.font = UIFont.systemFont(ofSize: 48, weight: .heavy)
        valueLabel.textColor = mockBalance >= 0 ? .success : .error
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
    
    private func createDetailRow(title: String, value: Double, color: UIColor) -> UIView {
        let container = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .primaryText
        
        let valueLabel = UILabel()
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
    
    private lazy var incomeRow = createDetailRow(title: "Total Income", value: mockIncomeTotal, color: .primary)
    private lazy var expensesRow = createDetailRow(title: "Total Expenses", value: mockExpenseTotal, color: .error)
    
    private lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = .border
        return view
    }()
    
    private lazy var netBalanceRow = createDetailRow(title: "Net Balance", value: mockBalance, color: mockBalance >= 0 ? .success : .error)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        setupUI()
    }
    
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
