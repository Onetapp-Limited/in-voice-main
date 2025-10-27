import UIKit
import SnapKit

class InvoiceDetailViewController: UIViewController {
    
    // MARK: - Properties
    
    var invoice: Invoice? // Invoice to display (must be set before presenting)
    private let itemCellHeight: CGFloat = 60
    private var tableViewHeightConstraint: Constraint!
    
    // MARK: - UI Elements
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header Info
    private let titleLabel = InvoiceDetailViewController.createMainLabel(text: "Invoice Title")
    private let clientTitleLabel = InvoiceDetailViewController.createSectionHeader(text: "CLIENT")
    private let clientLabel = InvoiceDetailViewController.createDetailLabel(text: "N/A")
    private lazy var statusLabel = InvoiceDetailViewController.createStatusLabel(status: "Pending")
    
    // Date Info
    private let dateTitleLabel = InvoiceDetailViewController.createSectionHeader(text: "DATES")
    private let invoiceDateLabel = InvoiceDetailViewController.createDetailLabel(text: "Invoice Date: N/A")
    private let dueDateLabel = InvoiceDetailViewController.createDetailLabel(text: "Due Date: N/A")
    
    // Items Table View
    private let itemsTitleLabel = InvoiceDetailViewController.createSectionHeader(text: "LINE ITEMS")
    private lazy var itemsTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register( InvoiceDetailItemCell.self, forCellReuseIdentifier:  InvoiceDetailItemCell.reuseIdentifier)
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .secondarySystemBackground
        tableView.layer.cornerRadius = 10
        return tableView
    }()
    
    // Summary
    private let subtotalLabel = InvoiceDetailViewController.createSummaryLabel(title: "Subtotal")
    private let taxLabel = InvoiceDetailViewController.createSummaryLabel(title: "Tax")
    private let discountLabel = InvoiceDetailViewController.createSummaryLabel(title: "Discount")
    private let totalLabel = InvoiceDetailViewController.createFinalTotalLabel(text: "Total: $0.00")
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewController()
        setupUI()
        
        // Mock data if no invoice is set, for immediate visual feedback
        if invoice == nil {
            invoice = mockInvoiceData()
        }
        
        if let invoice = invoice {
            configure(with: invoice)
        }
    }
    
    // MARK: - Setup
    
    private func setupViewController() {
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        title = "Invoice Details"
        
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editTapped))
        editButton.tintColor = .systemBlue
        navigationItem.rightBarButtonItem = editButton
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.backgroundColor = .systemBackground
        
        [titleLabel, clientTitleLabel, clientLabel, statusLabel, dateTitleLabel,
         invoiceDateLabel, dueDateLabel, itemsTitleLabel, itemsTableView,
         subtotalLabel, taxLabel, discountLabel, totalLabel].forEach { contentView.addSubview($0) }
        
        // 1. Scroll View Constraints
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        // 2. Content View Constraints
        contentView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalTo(view)
            make.width.equalTo(view)
        }
        
        let padding: CGFloat = 20
        var lastView: UIView = contentView
        
        // 3. Layout Subviews
        
        // Title (Main Header)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(padding)
            make.leading.equalToSuperview().inset(padding)
            make.trailing.equalTo(statusLabel.snp.leading).offset(-10)
        }
        lastView = titleLabel
        
        // Status Label (right aligned)
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.top).offset(5)
            make.trailing.equalToSuperview().inset(padding)
        }
        
        // Client Section
        clientTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(padding * 1.5)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        lastView = clientTitleLabel
        
        clientLabel.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        lastView = clientLabel
        
        // Dates Section
        dateTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(padding)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        lastView = dateTitleLabel

        invoiceDateLabel.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(5)
            make.leading.equalToSuperview().inset(padding)
        }
        
        dueDateLabel.snp.makeConstraints { make in
            make.top.equalTo(invoiceDateLabel.snp.bottom).offset(5)
            make.leading.equalToSuperview().inset(padding)
        }
        lastView = dueDateLabel
        
        // Items Section Header
        itemsTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(padding)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        lastView = itemsTitleLabel
        
        // Items Table View (Dynamic Height)
        itemsTableView.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(padding)
            tableViewHeightConstraint = make.height.equalTo(0).constraint // Initialize dynamic height
        }
        lastView = itemsTableView
        
        // Summary Stack (for Subtotal, Tax, Discount)
        let summaryStack = UIStackView(arrangedSubviews: [subtotalLabel, taxLabel, discountLabel])
        summaryStack.axis = .vertical
        summaryStack.spacing = 5
        contentView.addSubview(summaryStack)
        
        summaryStack.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(padding)
            make.trailing.equalToSuperview().inset(padding)
            make.leading.equalToSuperview().inset(padding * 3)
        }
        lastView = summaryStack
        
        // Total Label (Large)
        totalLabel.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(15)
            make.trailing.equalToSuperview().inset(padding)
            // Define bottom of content view
            make.bottom.equalTo(contentView.snp.bottom).inset(padding * 2)
        }
    }
    
    // MARK: - Data Configuration
    
    func configure(with invoice: Invoice) {
        // Header
        titleLabel.text = invoice.invoiceTitle
        clientLabel.text = invoice.client?.clientName ?? "No Client Selected"
        statusLabel.text = invoice.status
        
        // Dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        invoiceDateLabel.text = "Invoice Date: \(dateFormatter.string(from: invoice.invoiceDate))"
        dueDateLabel.text = "Due Date: \(dateFormatter.string(from: invoice.dueDate))"
        
        updateTableViewHeight()
        updateInvoiceSummary()
    }
    
    private func updateTableViewHeight() {
        // Recalculate and update the table view height constraint
        let count = invoice?.items.count ?? 0
        let height = CGFloat(count) * itemCellHeight
        tableViewHeightConstraint.update(offset: height)
        itemsTableView.reloadData()
        
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateInvoiceSummary() {
        guard let invoice = invoice else { return }
        
        let subtotal = invoice.items.reduce(0) { $0 + $1.lineTotal }
        let taxRate = invoice.taxRate
        let discount = invoice.discount
        
        let taxableSubtotal = max(0, subtotal - discount)
        let taxAmount = taxableSubtotal * taxRate
        let total = taxableSubtotal + taxAmount
        
        subtotalLabel.text = InvoiceDetailViewController.formatSummary(title: "Subtotal", amount: subtotal)
        taxLabel.text = InvoiceDetailViewController.formatSummary(title: "Tax (\((taxRate * 100).formatted(.number.precision(.fractionLength(0...2))))%)", amount: taxAmount)
        discountLabel.text = InvoiceDetailViewController.formatSummary(title: "Discount", amount: discount)

        totalLabel.text = "Total: \(total.formatted(.currency(code: "USD")))"
        
        // Update status appearance
        InvoiceDetailViewController.updateStatusLabelAppearance(statusLabel, status: invoice.status)
    }

    // MARK: - Helpers
    
    private static func createMainLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .label
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.numberOfLines = 0
        return label
    }

    private static func createSectionHeader(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        return label
    }
    
    private static func createDetailLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .label
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.numberOfLines = 0
        return label
    }
    
    private static func createStatusLabel(status: String) -> UILabel {
        let label = UILabel()
        label.text = status
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(80)
        }
        updateStatusLabelAppearance(label, status: status)
        return label
    }
    
    private static func updateStatusLabelAppearance(_ label: UILabel, status: String) {
        switch status.lowercased() {
        case "paid":
            label.backgroundColor = .systemGreen
        case "pending":
            label.backgroundColor = .systemOrange
        case "draft":
            label.backgroundColor = .systemGray
        default:
            label.backgroundColor = .systemBlue
        }
    }
    
    private static func formatSummary(title: String, amount: Double) -> String {
        let currency = amount.formatted(.currency(code: "USD"))
        return "\(title): \(currency)"
    }
    
    private static func createSummaryLabel(title: String) -> UILabel {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.text = formatSummary(title: title, amount: 0.0)
        label.textAlignment = .right
        return label
    }
    
    private static func createFinalTotalLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .label
        label.font = .systemFont(ofSize: 24, weight: .heavy)
        label.textAlignment = .right
        return label
    }

    // MARK: - Mock Data (for testing the detail view)

    private func mockInvoiceData() -> Invoice {
        let client = Client(id: UUID(), clientName: "Acme Tech Solutions", address: "123 Business Ln, Metropolis")
        let item1 = InvoiceItem(description: "iOS Development, 40 hours @ $120/hr", quantity: 40.0, unitPrice: 120.00)
        let item2 = InvoiceItem(description: "UI/UX Design, 10 hours @ $80/hr", quantity: 10.0, unitPrice: 80.00)
        
        var invoice = Invoice(
            invoiceTitle: "Project Alpha: Mobile App MVP",
            client: client,
            items: [item1, item2],
            taxRate: 0.05, // 5% tax
            discount: 50.00, // $50 flat discount
            invoiceDate: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            dueDate: Calendar.current.date(byAdding: .day, value: 20, to: Date())!,
            status: "Pending"
        )
        // Add one more item to show scrolling/list length
        invoice.items.append(InvoiceItem(description: "Server Hosting (Monthly)", quantity: 1.0, unitPrice: 200.00))
        
        return invoice
    }
    
    // MARK: - Actions
    
    @objc private func editTapped() {
        // Логика перехода к редактированию
        print("Edit Invoice Tapped - Opens NewInvoiceViewController for editing")
    }
}

// MARK: - Table View Data Source & Delegate

extension InvoiceDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return invoice?.items.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier:  InvoiceDetailItemCell.reuseIdentifier, for: indexPath) as?  InvoiceDetailItemCell,
              let item = invoice?.items[indexPath.row] else {
            return UITableViewCell()
        }
        cell.configure(with: item)
        cell.selectionStyle = .none // Отключаем выбор ячеек
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return itemCellHeight
    }
}
