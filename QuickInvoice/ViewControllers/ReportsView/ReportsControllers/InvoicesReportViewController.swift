import UIKit
import SnapKit
import DGCharts

class InvoicesReportViewController: UIViewController {
    
    private var invoiceService: InvoiceService? {
        do {
            return try InvoiceService()
        } catch {
            print("Failed to initialize InvoiceService: \(error)")
            return nil
        }
    }
    
    private var mockMonthlyData: [Double] {
        invoiceService?.getAllInvoices().map { invoice in
            invoice.items.reduce(0) { $0 + $1.lineTotal }
        } ?? []
    }
    
    private lazy var dailyIncomeData: [Double] = self.processDailyIncome()
    
    private lazy var mockSummary = setupMockSummary()

    private lazy var mockClientSales: [(client: String, earned: Double, paid: Double)] = setupMockClientSales()
    
    // MARK: - Chart Views
    
    // Реальный Line Chart из библиотеки Charts
    private lazy var lineChartView: LineChartView = {
        let chart = LineChartView()
        chart.noDataText = "No data for Line Chart."
        chart.backgroundColor = .surface
        return chart
    }()
    
    // Реальный Bar Chart из библиотеки Charts
    private lazy var barChartView: BarChartView = {
        let chart = BarChartView()
        chart.noDataText = "No data for Bar Chart."
        chart.backgroundColor = .surface
        return chart
    }()
    
    // MARK: - UI Components
    
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
        label.text = "Daily Income"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .primaryText
        return label
    }()
    
    private lazy var chartTypeSegment: UISegmentedControl = {
        let items = ["Bar", "Line"]
        let segment = UISegmentedControl(items: items)
        segment.selectedSegmentTintColor = UIColor.primaryLight
        segment.backgroundColor = UIColor.backgroundSecondary
        segment.selectedSegmentIndex = 1
        
        let font = UIFont.systemFont(ofSize: 13, weight: .medium)
        segment.setTitleTextAttributes([.font: font], for: .normal)
        segment.setTitleTextAttributes([.font: font, .foregroundColor: UIColor.primaryText], for: .selected)
        
        segment.addTarget(self, action: #selector(toggleChartType), for: .valueChanged)
        return segment
    }()
    
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
        // Настройка и отображение данных
        renderChartData()
        updateChartDisplay()
    }
    
    // MARK: - Chart Data Setup
    
    private func setupChartData(for chartView: ChartViewBase) {
        let entries = dailyIncomeData.enumerated().map { (index, value) -> ChartDataEntry in
            ChartDataEntry(x: Double(index), y: value)
        }
        
        // Обертка для конверсии ChartDataEntry → BarChartDataEntry
        func barEntries(from chartEntries: [ChartDataEntry]) -> [BarChartDataEntry] {
            chartEntries.map { BarChartDataEntry(x: $0.x, y: $0.y) }
        }
        
        if let lineChart = chartView as? LineChartView {
            let dataSet = LineChartDataSet(entries: entries, label: "Daily Income")
            dataSet.colors = [.systemMint]
            dataSet.circleColors = [.systemMint]
            dataSet.lineWidth = 2.0
            dataSet.circleRadius = 4.0
            dataSet.drawValuesEnabled = false
            
            lineChart.data = LineChartData(dataSet: dataSet)
            
        } else if let barChart = chartView as? BarChartView {
            let barEntries = barEntries(from: entries)
            let dataSet = BarChartDataSet(entries: barEntries, label: "Daily Income")
            dataSet.colors = [.systemOrange]
            dataSet.drawValuesEnabled = false
            
            barChart.data = BarChartData(dataSet: dataSet)
        }
        
        chartView.animate(yAxisDuration: 0.5)
    }

    private func renderChartData() {
        // Загружаем данные в оба графика
        setupChartData(for: lineChartView)
        setupChartData(for: barChartView)
    }
    
    // MARK: - UI Setup
    
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
        
        chartContainer.addSubview(lineChartView)
        chartContainer.addSubview(barChartView)
        
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
        
        let chartViews: [UIView] = [lineChartView, barChartView]
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
    
    // MARK: - Data Processing
    
    private func parseTotalAmount(_ value: String) -> Double {
        let cleaned = value
            .replacingOccurrences(of: "[^0-9.,-]", with: "", options: .regularExpression)
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned) ?? 0
    }
    
    private func processDailyIncome() -> [Double] {
        guard let invoices = invoiceService?.getAllInvoices() else { return [] }
        
        let groupedByDate = Dictionary(grouping: invoices) { invoice -> Date in
            let date = invoice.invoiceDate
            let calendar = Calendar.current
            return calendar.startOfDay(for: date)
        }
        
        let dailyTotals = groupedByDate.compactMapValues { dailyInvoices in
            dailyInvoices.reduce(0) { $0 + parseTotalAmount($1.totalAmount) }
        }
        
        let sortedDates = dailyTotals.keys.sorted()
        
        return sortedDates.map { dailyTotals[$0]! }
    }
    
    private func setupMockSummary() -> (paid: Double, unpaid: Double, total: Double) {
        guard let invoices = invoiceService?.getAllInvoices() else {
            return (0, 0, 0)
        }

        let paid = invoices.filter { $0.status == .paid }.reduce(0) { $0 + parseTotalAmount($1.totalAmount) }
        let unpaid = invoices.filter { $0.status != .paid }.reduce(0) { $0 + parseTotalAmount($1.totalAmount) }
        let total = invoices.reduce(0) { $0 + parseTotalAmount($1.totalAmount) }

        return (paid, unpaid, total)
    }
    
    private func setupMockClientSales() -> [(client: String, earned: Double, paid: Double)] {
        guard let invoices = invoiceService?.getAllInvoices() else {
            return []
        }
        
        let grouped = Dictionary(grouping: invoices) { invoice in
            invoice.client?.clientName ?? "Unknown Client"
        }
        
        let result = grouped.map { (clientName, clientInvoices) -> (client: String, earned: Double, paid: Double) in
            let earned = clientInvoices.reduce(0) { $0 + parseTotalAmount($1.totalAmount) }
            let paid = clientInvoices
                .filter { $0.status == .paid }
                .reduce(0) { $0 + parseTotalAmount($1.totalAmount) }
            return (client: clientName, earned: earned, paid: paid)
        }
        
        return result.sorted { $0.earned > $1.earned }
    }
    
    // MARK: - Actions
    
    @objc private func toggleChartType(_ sender: UISegmentedControl) {
        updateChartDisplay()
    }
    
    private func updateChartDisplay() {
        let selectedIndex = chartTypeSegment.selectedSegmentIndex
        
        lineChartView.isHidden = true
        barChartView.isHidden = true
        
        if selectedIndex == 0 { // Bar
            barChartView.isHidden = false
            chartTitleLabel.text = "Daily Income"
        } else if selectedIndex == 1 { // Line
            lineChartView.isHidden = false
            chartTitleLabel.text = "Daily Income"
        }
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
