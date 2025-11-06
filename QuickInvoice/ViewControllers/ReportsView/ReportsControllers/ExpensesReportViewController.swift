import UIKit
import SnapKit
import DGCharts

class ExpensesReportViewController: UIViewController {
    
    private let mockExpenseData: [Double] = [1200.0, 850.0, 1500.0, 700.0, 1000.0, 950.0, 1100.0]
    
    private lazy var mockSummary = setupMockSummary()
    
    private lazy var mockClientSales: [(client: String, spent: Double)] = []
    
    private lazy var lineChartView: LineChartView = {
        let chart = LineChartView()
        chart.noDataText = ""
        chart.backgroundColor = .surface
        chart.isUserInteractionEnabled = false
        return chart
    }()
    
    private lazy var barChartView: BarChartView = {
        let chart = BarChartView()
        chart.noDataText = ""
        chart.backgroundColor = .surface
        chart.isUserInteractionEnabled = false
        return chart
    }()
    
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
        label.text = "Daily Expenses"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .primaryText
        return label
    }()
    
    private lazy var chartTypeSegment: UISegmentedControl = {
        let items = ["Bar", "Line"]
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

    private lazy var noDataOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.surface.withAlphaComponent(0.85)
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        
        let label = UILabel()
        label.text = "No current data for this reporting period 😕\nPlease adjust the filter."
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .primaryText
        label.numberOfLines = 0
        label.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [label])
        stack.axis = .vertical
        stack.alignment = .center
        
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
        return view
    }()
    
    private lazy var salesTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Expenses by Category"
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        setupTableView()
        setupUI()
        
        setupChartData(for: lineChartView)
        setupChartData(for: barChartView)
        
        updateChartDisplay()
        displayNoDataOverlay()
    }
    
    private func setupChartData(for chartView: ChartViewBase) {
        let entries = mockExpenseData.enumerated().map { (index, value) -> ChartDataEntry in
            ChartDataEntry(x: Double(index), y: value)
        }
        
        let days: [String] = (1...mockExpenseData.count).map { "Day \($0)" }
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: days)
        chartView.xAxis.granularity = 1.0

        func barEntries(from chartEntries: [ChartDataEntry]) -> [BarChartDataEntry] {
            chartEntries.map { BarChartDataEntry(x: $0.x, y: $0.y) }
        }
        
        if let lineChart = chartView as? LineChartView {
            let dataSet = LineChartDataSet(entries: entries, label: "Daily Expenses")
            dataSet.colors = [.systemRed.withAlphaComponent(0.5)]
            dataSet.circleColors = [.systemRed.withAlphaComponent(0.5)]
            dataSet.lineWidth = 2.0
            dataSet.circleRadius = 4.0
            dataSet.drawValuesEnabled = false
            lineChart.data = LineChartData(dataSet: dataSet)
            
        } else if let barChart = chartView as? BarChartView {
            let barEntries = barEntries(from: entries)
            let dataSet = BarChartDataSet(entries: barEntries, label: "Daily Expenses")
            dataSet.colors = [.systemRed.withAlphaComponent(0.5)]
            dataSet.drawValuesEnabled = false
            barChart.data = BarChartData(dataSet: dataSet)
        }
    }
    
    private func setupMockSummary() -> (paid: Double, unpaid: Double, total: Double) {
        let total = mockExpenseData.reduce(0, +)
        // Возвращаем только Total для Expenses, но используем кортеж для соответствия сигнатуре createSummaryCard
        return (paid: 0, unpaid: 0, total: total)
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Только одна карточка: Total Expenses
        let totalCard = createSummaryCard(title: "Total Expenses", value: mockSummary.total, color: .systemRed)

        summaryStackView.addArrangedSubview(totalCard)
        
        chartContainer.addSubview(chartTitleLabel)
        chartContainer.addSubview(chartTypeSegment)
        chartContainer.addSubview(lineChartView)
        chartContainer.addSubview(barChartView)
        chartContainer.addSubview(noDataOverlay)
        
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
            make.width.equalTo(120)
            make.height.equalTo(32)
        }
        
        let chartViews: [UIView] = [lineChartView, barChartView, noDataOverlay]
        chartViews.forEach { view in
            view.snp.makeConstraints { make in
                make.top.equalTo(chartTitleLabel.snp.bottom).offset(16)
                make.leading.trailing.equalToSuperview().inset(16)
                make.bottom.equalToSuperview().offset(-16)
            }
        }
        
        salesTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(chartContainer.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(20)
        }
        
        let tableHeight = CGFloat(max(1, mockClientSales.count) * 60)
        
        salesTableContainer.snp.makeConstraints { make in
            make.top.equalTo(salesTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(tableHeight)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        salesTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupTableView() {
        salesTableView.delegate = self
        salesTableView.dataSource = self
    }

    @objc private func toggleChartType(_ sender: UISegmentedControl) {
        updateChartDisplay()
    }
    
    private func updateChartDisplay() {
        let selectedIndex = chartTypeSegment.selectedSegmentIndex
        
        lineChartView.isHidden = true
        barChartView.isHidden = true
        
        if selectedIndex == 0 {
            barChartView.isHidden = false
            chartTitleLabel.text = "Daily Expenses"
        } else if selectedIndex == 1 {
            lineChartView.isHidden = false
            chartTitleLabel.text = "Daily Expenses"
        }
    }

    private func displayNoDataOverlay() {
        noDataOverlay.isHidden = false
        lineChartView.isUserInteractionEnabled = false
        barChartView.isUserInteractionEnabled = false
    }
    
    private func displayChart() {
        noDataOverlay.isHidden = true
        lineChartView.isUserInteractionEnabled = true
        barChartView.isUserInteractionEnabled = true
        let currentChart = chartTypeSegment.selectedSegmentIndex == 0 ? barChartView : lineChartView
        currentChart.animate(yAxisDuration: 0.5)
    }
}

extension ExpensesReportViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mockClientSales.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "No Category Data"
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }
}
