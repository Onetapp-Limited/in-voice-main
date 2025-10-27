import UIKit
import SnapKit

class NewInvoiceViewController: UIViewController {
    
    // MARK: - Properties
    
    var currentInvoice: Invoice = Invoice() // State for the invoice being created/edited
    private let itemCellHeight: CGFloat = 60
    private var tableViewHeightConstraint: Constraint! // Constraint for dynamic table height
    
    // MARK: - UI Elements
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header Fields
    private let titleTextField = createTextField(placeholder: "Invoice Title (e.g., Project Alpha)")
    private let clientButton = createButton(title: "Select Client", color: .secondary)
    
    // Dates
    private let dateLabel = createLabel(text: "Date:")
    private let datePicker = UIDatePicker()
    private let dueDateLabel = createLabel(text: "Due Date:")
    private let dueDatePicker = UIDatePicker()
    
    // Items Table View
    private lazy var itemsTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(InvoiceItemCell.self, forCellReuseIdentifier: InvoiceItemCell.reuseIdentifier)
        tableView.isScrollEnabled = false // Crucial when inside a UIScrollView
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .surface
        tableView.layer.cornerRadius = 10
        return tableView
    }()
    
    // Items Actions
    private let addItemButton = createButton(title: "Add Item", color: .primary)
    
    // Summary
    private let subtotalLabel = createSummaryLabel(text: "Subtotal: $0.00")
    private let taxTextField = createTextField(placeholder: "0.0", initialText: "0.0")
    private let discountTextField = createTextField(placeholder: "0.0", initialText: "0.0")
    private let totalLabel = createSummaryLabel(text: "Total: $0.00")
    
    // Footer
    private lazy var saveButton: GradientButton = {
        let button = GradientButton(type: .custom)
        button.setTitle("Save Invoice", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewController()
        setupUI()
        updateInvoiceSummary()
    }
    
    // MARK: - Setup
    
    private func setupViewController() {
        view.backgroundColor = .background
        
        let dismissButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissSelf))
        dismissButton.tintColor = .primary
        navigationItem.leftBarButtonItem = dismissButton
        
        // Add targets
        addItemButton.addTarget(self, action: #selector(addItemTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveInvoiceTapped), for: .touchUpInside)
        clientButton.addTarget(self, action: #selector(selectClientTapped), for: .touchUpInside)
        
        taxTextField.delegate = self
        discountTextField.delegate = self
        titleTextField.delegate = self
        
        datePicker.datePickerMode = .date
        dueDatePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        dueDatePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        taxTextField.keyboardType = .decimalPad
        discountTextField.keyboardType = .decimalPad
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add all subviews to contentView
        [titleTextField, clientButton, itemsTableView, addItemButton,
         subtotalLabel, totalLabel, saveButton].forEach { contentView.addSubview($0) }

        // Date and Tax/Discount fields are handled with stacks for layout
        let dateStack = createHStack(views: [dateLabel, datePicker], distribution: .fillProportionally)
        let dueDateStack = createHStack(views: [dueDateLabel, dueDatePicker], distribution: .fillProportionally)
        
        let taxStack = createHStack(views: [taxTextField, NewInvoiceViewController.createLabel(text: "Tax Rate (%)")])
        let discountStack = createHStack(views: [discountTextField, NewInvoiceViewController.createLabel(text: "Discount ($)")])
        
        // 1. Scroll View Constraints
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        // 2. Content View Constraints
        contentView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalTo(view)
            make.width.equalTo(view) // Crucial for vertical scrolling
        }
        
        let padding: CGFloat = 20
        var lastView: UIView = contentView // FIX: Initialize with a valid UIView to avoid the casting error.
        
        // 3. Layout Subviews
        
        // Title Field
        titleTextField.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(padding)
            make.leading.trailing.equalToSuperview().inset(padding)
        }
        lastView = titleTextField
        
        // Client Button
        clientButton.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(padding)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(50)
            clientButton.layer.cornerRadius = 8
        }
        lastView = clientButton
        
        // Dates Stacks
        dateStack.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(padding)
            make.leading.equalToSuperview().inset(padding)
            make.width.equalToSuperview().multipliedBy(0.45)
        }
        dueDateStack.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(padding)
            make.trailing.equalToSuperview().inset(padding)
            make.width.equalToSuperview().multipliedBy(0.45)
        }
        lastView = dateStack
        
        // Items Table View (Dynamic Height)
        itemsTableView.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(padding)
            make.leading.trailing.equalToSuperview().inset(padding)
            tableViewHeightConstraint = make.height.equalTo(0).constraint // Initialize dynamic height
        }
        lastView = itemsTableView
        
        // Add Item Button
        addItemButton.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(10)
            make.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(40)
            make.width.equalTo(120)
            addItemButton.layer.cornerRadius = 8
        }
        lastView = addItemButton
        
        // Summary Area
        
        // Subtotal
        subtotalLabel.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(padding * 1.5)
            make.trailing.equalToSuperview().inset(padding)
        }
        lastView = subtotalLabel
        
        // Tax Field
        taxStack.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(10)
            make.leading.equalToSuperview().inset(padding)
            make.height.equalTo(40)
            make.width.equalToSuperview().multipliedBy(0.45)
        }
        lastView = taxStack
        
        // Discount Field
        discountStack.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(10)
            make.leading.equalToSuperview().inset(padding)
            make.height.equalTo(40)
            make.width.equalToSuperview().multipliedBy(0.45)
        }
        lastView = discountStack
        
        // Total Label
        totalLabel.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(padding)
            make.trailing.equalToSuperview().inset(padding)
            totalLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        }
        lastView = totalLabel
        
        // Save Button (Gradient)
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(padding * 2)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(50)
            make.bottom.equalTo(contentView.snp.bottom).inset(padding) // Define bottom of content view
        }
        
        // Initialize fields
        titleTextField.text = currentInvoice.invoiceTitle
        taxTextField.text = String(currentInvoice.taxRate * 100)
        discountTextField.text = String(currentInvoice.discount)
        datePicker.date = currentInvoice.invoiceDate
        dueDatePicker.date = currentInvoice.dueDate
        
        updateTableViewHeight()
        updateClientDisplay()
    }
    
    // MARK: - Helpers
    
    private static func createTextField(placeholder: String, initialText: String? = nil) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.text = initialText
        tf.borderStyle = .none
        tf.backgroundColor = .surface
        tf.textColor = .primaryText
        tf.layer.cornerRadius = 8
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: tf.frame.height))
        tf.leftViewMode = .always
        tf.textAlignment = .right
        return tf
    }
    
    private static func createButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.setTitleColor(color == .secondary ? .primaryText : .white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        return button
    }
    
    private static func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .primaryText
        return label
    }
    
    private static func createSummaryLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .primaryText
        label.font = .systemFont(ofSize: 18, weight: .medium)
        return label
    }
    
    private func createHStack(views: [UIView], distribution: UIStackView.Distribution = .fill) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = distribution
        contentView.addSubview(stack)
        return stack
    }

    // MARK: - Data Management & Calculations
    
    private func updateClientDisplay() {
        let clientName = currentInvoice.client?.clientName ?? "Select Client"
        clientButton.setTitle(clientName, for: .normal)
    }
    
    private func updateTableViewHeight() {
        // Recalculate and update the table view height constraint
        let height = CGFloat(currentInvoice.items.count) * itemCellHeight
        tableViewHeightConstraint.update(offset: height)
        itemsTableView.reloadData()
        
        // Force layout update to ensure scroll view size is correct
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateInvoiceSummary() {
        let subtotal = currentInvoice.items.reduce(0) { $0 + $1.lineTotal }
        
        // Parse and set tax rate
        let taxRate = Double(taxTextField.text ?? "0.0") ?? 0.0
        currentInvoice.taxRate = max(0, taxRate / 100.0) // Store as 0.XX (ensure non-negative)
        
        // Parse and set discount
        let discount = Double(discountTextField.text ?? "0.0") ?? 0.0
        currentInvoice.discount = max(0, discount) // Ensure non-negative
        
        let taxableSubtotal = max(0, subtotal - currentInvoice.discount)
        let taxAmount = taxableSubtotal * currentInvoice.taxRate
        let total = taxableSubtotal + taxAmount
        
        subtotalLabel.text = "Subtotal: \(subtotal.formatted(.currency(code: "USD")))"
        totalLabel.text = "Total: \(total.formatted(.currency(code: "USD")))"
        
        // Update text fields if they were invalid (e.g., negative input)
        taxTextField.text = String((currentInvoice.taxRate * 100).formatted(.number.precision(.fractionLength(0...2))))
        discountTextField.text = String(currentInvoice.discount.formatted(.number.precision(.fractionLength(0...2))))
    }

    // MARK: - Actions
    
    @objc private func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func dateChanged() {
        currentInvoice.invoiceDate = datePicker.date
        currentInvoice.dueDate = dueDatePicker.date
    }
    
    @objc private func selectClientTapped() {
        // TODO: Implement logic to select client (e.g., present a ClientListVC)
        print("Select Client Tapped - Mocking selection")
        currentInvoice.client = Client(id: UUID(), clientName: "Acme Corp.", address: "123 Business Ln")
        updateClientDisplay()
    }
    
    @objc private func addItemTapped() {
        // TODO: Implement logic to add a new item via a modal/alert
        print("Add Item Tapped - Mocking item creation")
        
        // Mock: Add a default item and refresh
        let newItem = InvoiceItem(description: "Consulting Fee", quantity: 10.0, unitPrice: 120.00)
        currentInvoice.items.append(newItem)
        
        // Use insertRows for smooth animation
        itemsTableView.insertRows(at: [IndexPath(row: currentInvoice.items.count - 1, section: 0)], with: .automatic)
        updateTableViewHeight()
        updateInvoiceSummary()
    }
    
    @objc private func saveInvoiceTapped() {
        // Finalize data
        currentInvoice.invoiceTitle = titleTextField.text
        
        // TODO: Implement actual persistence logic (Firestore/Core Data)
        print("--- Saving Invoice ---")
        print("Title: \(currentInvoice.invoiceTitle ?? "")")
        print("Client: \(currentInvoice.client?.clientName ?? "None")")
        print("Total Items: \(currentInvoice.items.count)")
        print("Tax Rate: \(currentInvoice.taxRate * 100)%")
        print("Discount: $\(currentInvoice.discount)")
        print("Final Total: \(totalLabel.text ?? "")")
        print("----------------------")
        
        // Dismiss after save
        dismissSelf()
    }
}

// MARK: - Table View Data Source & Delegate

extension NewInvoiceViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentInvoice.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InvoiceItemCell.reuseIdentifier, for: indexPath) as? InvoiceItemCell else {
            return UITableViewCell()
        }
        let item = currentInvoice.items[indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return itemCellHeight
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            currentInvoice.items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            updateTableViewHeight()
            updateInvoiceSummary()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // TODO: Logic to edit the selected item (e.g., presenting a modal to update quantity/price/description)
        print("Edit item at \(indexPath.row)")
    }
}

// MARK: - Text Field Delegate

extension NewInvoiceViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Recalculate summary when tax or discount fields are edited
        if textField == taxTextField || textField == discountTextField {
            updateInvoiceSummary()
        } else if textField == titleTextField {
            currentInvoice.invoiceTitle = textField.text
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
