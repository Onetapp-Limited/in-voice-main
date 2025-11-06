import UIKit
import SnapKit

class InvoicesReportViewController: UIViewController {
    
    private var mockMonthlyData: [Double] = [5000, 7500, 12000, 15000, 10500, 18000]
    private var mockSummary = (paid: 25000.0, unpaid: 8000.0, total: 33000.0)
    private var mockClientSales: [(client: String, earned: Double, paid: Double)] = [
        ("Tech Innovators Co.", 15000.0, 10000.0),
        ("Global Dynamics Inc.", 8000.0, 8000.0),
        ("Sunrise Marketing Agency", 10000.0, 7000.0)
    ]
    
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
    
    // MARK: - Summary Cards
    
    private lazy var summaryStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
        return stack
    }()
    
    private func createSummaryCard(title: String, value: Double, color: UIColor) -> UIView {
        let container = UIView()
        container.backgroundColor = .surface
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.08
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 8
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .secondaryText
        
        let valueLabel = UILabel()
        valueLabel.text = "$\(Int(value).formattedWithSeparator)"
        valueLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        valueLabel.textColor = color
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.8
        
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        return container
    }
    
    // MARK: - Chart Section
    
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
        label.text = "Monthly Income"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .primaryText
        return label
    }()
    
    private lazy var chartTypeSegment: UISegmentedControl = {
        let items = ["Chart", "Table"]
        let segment = UISegmentedControl(items: items)
        segment.selectedSegmentTintColor = UIColor.primaryLight
        segment.backgroundColor = UIColor.backgroundSecondary
        segment.selectedSegmentIndex = 0
        
        let font = UIFont.systemFont(ofSize: 13, weight: .medium)
        segment.setTitleTextAttributes([.font: font], for: .normal)
        segment.setTitleTextAttributes([.font: font, .foregroundColor: UIColor.primaryText], for: .selected)
        
        segment.addTarget(self, action: #selector(toggleChartType), for: .valueChanged)
        return segment
    }()
    
    private lazy var chartPlaceholder: UILabel = {
        let label = UILabel()
        label.text = "📊\n\nLine Chart\nMonthly Income Trends"
        label.textColor = .secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.backgroundColor = .backgroundSecondary
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }()
    
    // MARK: - Sales Table Section
    
    private lazy var salesTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Sales by Client"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .primaryText
        return label
    }()
    
    private lazy var salesTableContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .surface
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        return view
    }()
    
    private lazy var salesTableView: UITableView = {
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
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        setupTableView()
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        let paidCard = createSummaryCard(title: "Paid", value: mockSummary.paid, color: .success)
        let unpaidCard = createSummaryCard(title: "Unpaid", value: mockSummary.unpaid, color: .warning)
        let totalCard = createSummaryCard(title: "Total", value: mockSummary.total, color: .primary)
        
        summaryStackView.addArrangedSubview(paidCard)
        summaryStackView.addArrangedSubview(unpaidCard)
        summaryStackView.addArrangedSubview(totalCard)
        
        chartContainer.addSubview(chartTitleLabel)
        chartContainer.addSubview(chartTypeSegment)
        chartContainer.addSubview(chartPlaceholder)
        
        salesTableContainer.addSubview(salesTableView)
        
        contentView.addSubview(summaryStackView)
        contentView.addSubview(chartContainer)
        contentView.addSubview(salesTitleLabel)
        contentView.addSubview(salesTableContainer)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }
        
        summaryStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(90)
        }
        
        chartContainer.snp.makeConstraints { make in
            make.top.equalTo(summaryStackView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(280)
        }
        
        chartTitleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }
        
        chartTypeSegment.snp.makeConstraints { make in
            make.centerY.equalTo(chartTitleLabel)
            make.trailing.equalToSuperview().offset(-16)
            make.width.equalTo(140)
            make.height.equalTo(32)
        }
        
        chartPlaceholder.snp.makeConstraints { make in
            make.top.equalTo(chartTitleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        salesTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(chartContainer.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(20)
        }
        
        salesTableContainer.snp.makeConstraints { make in
            make.top.equalTo(salesTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(CGFloat(mockClientSales.count * 60))
            make.bottom.equalToSuperview().offset(-20)
        }
        
        salesTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupTableView() {
        salesTableView.delegate = self
        salesTableView.dataSource = self
        salesTableView.register(ClientSalesCell.self, forCellReuseIdentifier: ClientSalesCell.reuseIdentifier)
    }
    
    @objc private func toggleChartType(_ sender: UISegmentedControl) {
        let isChart = sender.selectedSegmentIndex == 0
        chartPlaceholder.text = isChart ? "📊\n\nLine Chart\nMonthly Income Trends" : "📋\n\nTable View\nMonthly Income Data"
    }
}

// MARK: - Invoices Table Delegate

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
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        return cell
    }
}
