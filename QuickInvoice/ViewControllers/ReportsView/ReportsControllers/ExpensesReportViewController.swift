import UIKit
import SnapKit
import DGCharts

class ExpensesReportViewController: UIViewController {
    
    // 1. Добавляем InvoiceService
    private var invoiceService: InvoiceService? {
        do {
            return try InvoiceService()
        } catch {
            print("Failed to initialize InvoiceService: \(error)")
            return nil
        }
    }
    
    // 2. ИЗМЕНЕНИЕ: Теперь храним реальные данные о расходах (VAT/Tax) с датами
    private lazy var dailyExpenseData: (values: [Double], dates: [Date]) = self.processDailyExpenses()
    
    // 3. ИЗМЕНЕНИЕ: Используем реальное суммарное значение
    private lazy var mockSummary = setupMockSummary()
    
    // 4. ИЗМЕНЕНИЕ: Загружаем расходы по категориям
    private lazy var mockClientSales: [(category: String, spent: Double)] = self.setupExpensesByCategory()
    
    // MARK: - UI Components
    
    private lazy var lineChartView: LineChartView = {
        let chart = LineChartView()
        chart.noDataText = ""
        chart.backgroundColor = .surface
        chart.isUserInteractionEnabled = true
        return chart
    }()
    
    private lazy var barChartView: BarChartView = {
        let chart = BarChartView()
        chart.noDataText = ""
        chart.backgroundColor = .surface
        chart.isUserInteractionEnabled = true
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
    
    // Оставляем только одну карточку для Total Expenses
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
        // Предполагаем, что extension Int/Double.formattedWithSeparator доступен
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
        label.text = "Expenses by Client (VAT/Tax source)" // Отражаем, что это сумма VAT/Tax по клиентам
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
        // Нужно зарегистрировать ячейку, если она используется (например, ClientSalesCell)
        // table.register(ClientSalesCell.self, forCellReuseIdentifier: ClientSalesCell.reuseIdentifier)
        return table
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        setupTableView()
        setupUI()
        
        // Загрузка данных в графики
        setupChartData(for: lineChartView)
        setupChartData(for: barChartView)
        
        // 🔑 Логика отображения заглушки/данных
        if dailyExpenseData.values.isEmpty {
            displayNoDataOverlay()
        } else {
            displayChart()
        }
        updateChartDisplay()
    }
    
    // MARK: - Data Processing (Обновлено)
    
    // Вспомогательная функция для парсинга, если totalAmount сохраняется строкой
    private func parseTotalAmount(_ value: String) -> Double {
        let cleaned = value
            .replacingOccurrences(of: "[^0-9.,-]", with: "", options: .regularExpression)
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned) ?? 0
    }
    
    // 🔑 ИЗМЕНЕНИЕ: Обрабатываем Daily Expenses (TaxTotal)
    private func processDailyExpenses() -> (values: [Double], dates: [Date]) {
        guard let invoices = invoiceService?.getAllInvoices() else { return ([], []) }
        
        let groupedByDate = Dictionary(grouping: invoices) { invoice -> Date in
            let calendar = Calendar.current
            return calendar.startOfDay(for: invoice.invoiceDate)
        }
        
        // Суммируем taxTotal (VAT/Tax) для всех инвойсов за каждый день
        let dailyTotals = groupedByDate.compactMapValues { dailyInvoices in
            dailyInvoices.reduce(0) { $0 + $1.taxTotal }
        }
        
        let sortedDates = dailyTotals.keys.sorted()
        
        let values = sortedDates.map { dailyTotals[$0]! }
        
        return (values, sortedDates)
    }
    
    // 🔑 ИЗМЕНЕНИЕ: Суммарный Total Expense
    private func setupMockSummary() -> (paid: Double, unpaid: Double, total: Double) {
        guard let invoices = invoiceService?.getAllInvoices() else {
            return (0, 0, 0)
        }
        
        // Общий расход = сумма taxTotal всех инвойсов
        let totalExpense = invoices.reduce(0) { $0 + $1.taxTotal }
        
        // Используем кортеж для соответствия сигнатуре, но возвращаем только Total
        return (paid: 0, unpaid: 0, total: totalExpense)
    }
    
    // 🔑 ИЗМЕНЕНИЕ: Расходы по клиентам (Сумма VAT/Tax с каждого клиента)
    private func setupExpensesByCategory() -> [(category: String, spent: Double)] {
        guard let invoices = invoiceService?.getAllInvoices() else {
            return []
        }
        
        // Группируем по клиенту (аналог категории в данном контексте)
        let grouped = Dictionary(grouping: invoices) { invoice in
            invoice.client?.clientName ?? "Unknown Client"
        }
        
        let result = grouped.map { (clientName, clientInvoices) -> (category: String, spent: Double) in
            // Суммируем TaxTotal всех инвойсов данного клиента
            let spent = clientInvoices.reduce(0) { $0 + $1.taxTotal }
            return (category: clientName, spent: spent)
        }
        
        // Сортируем по сумме расходов
        return result.sorted { $0.spent > $1.spent }
    }
    
    // MARK: - Chart Setup (Обновлено для работы с датами)
    
    private func setupChartData(for chartView: ChartViewBase) {
        // Используем реальные данные о расходах
        let entries = dailyExpenseData.values.enumerated().map { (index, value) -> ChartDataEntry in
            ChartDataEntry(x: Double(index), y: value)
        }
        
        // Применяем форматер для даты
        let dateFormatter = DateAxisValueFormatter(dates: dailyExpenseData.dates)
        
        chartView.xAxis.valueFormatter = dateFormatter
        chartView.xAxis.granularity = 1.0 // Метка для каждого дня
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.drawGridLinesEnabled = false // Чистый вид
        
        // Убираем описание по умолчанию
        chartView.legend.enabled = false
        chartView.chartDescription.enabled = false

        func barEntries(from chartEntries: [ChartDataEntry]) -> [BarChartDataEntry] {
            chartEntries.map { BarChartDataEntry(x: $0.x, y: $0.y) }
        }
        
        if let lineChart = chartView as? LineChartView {
            let dataSet = LineChartDataSet(entries: entries, label: "Daily Expenses")
            // Используем красный цвет для расходов
            dataSet.colors = [.systemRed]
            dataSet.circleColors = [.systemRed]
            dataSet.lineWidth = 2.0
            dataSet.circleRadius = 4.0
            dataSet.drawValuesEnabled = false
            lineChart.data = LineChartData(dataSet: dataSet)
            
        } else if let barChart = chartView as? BarChartView {
            let barEntries = barEntries(from: entries)
            let dataSet = BarChartDataSet(entries: barEntries, label: "Daily Expenses")
            // Используем красный цвет для расходов
            dataSet.colors = [.systemRed]
            dataSet.drawValuesEnabled = false
            barChart.data = BarChartData(dataSet: dataSet)
        }
    }
    
    // MARK: - UI Setup (Без изменений, кроме одной карточки)
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Только одна карточка: Total Expenses
        let totalCard = createSummaryCard(title: "Total Expenses (VAT/Tax)", value: mockSummary.total, color: .systemRed)

        summaryStackView.addArrangedSubview(totalCard)
        // ... (Остальной setupUI без изменений, кроме того, что мы удалили ненужные карточки Paid/Unpaid)
        
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
        
        // 🔑 ИЗМЕНЕНИЕ: Высота таблицы теперь зависит от реальных данных
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
        // Здесь должна быть регистрация ячейки (например, ExpenseCategoryCell.self)
    }

    @objc private func toggleChartType(_ sender: UISegmentedControl) {
        updateChartDisplay()
    }
    
    private func updateChartDisplay() {
        let selectedIndex = chartTypeSegment.selectedSegmentIndex
        
        lineChartView.isHidden = true
        barChartView.isHidden = true
        
        if dailyExpenseData.values.isEmpty {
            // Если данных нет, показываем только заглушку
            displayNoDataOverlay()
        } else {
            // Если данные есть, показываем выбранный график
            displayChart()
            if selectedIndex == 0 {
                barChartView.isHidden = false
            } else if selectedIndex == 1 {
                lineChartView.isHidden = false
            }
        }
    }

    // 🔑 ИЗМЕНЕНИЕ: Логика показа/скрытия
    private func displayNoDataOverlay() {
        noDataOverlay.isHidden = false
        lineChartView.isHidden = true
        barChartView.isHidden = true
    }
    
    private func displayChart() {
        noDataOverlay.isHidden = true
        // isUserInteractionEnabled можно оставить true, т.к. данные есть
        let currentChart = chartTypeSegment.selectedSegmentIndex == 0 ? barChartView : lineChartView
        currentChart.animate(yAxisDuration: 0.5)
    }
}

// MARK: - Table View Delegate & Data Source (Обновлено)

extension ExpensesReportViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Используем реальные данные
        return mockClientSales.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Здесь должна быть кастомная ячейка ExpenseCategoryCell, но пока используем стандартную для демонстрации данных:
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "ExpenseCell")
        let data = mockClientSales[indexPath.row]
        
        cell.textLabel?.text = data.category
        cell.detailTextLabel?.text = "$\(Int(data.spent).formattedWithSeparator)"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }
}
