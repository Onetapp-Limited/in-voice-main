import UIKit
import SnapKit

class NewInvoiceViewController: UIViewController {
    
    // MARK: - Properties
    var currentInvoice: Invoice = Invoice()
    private let itemCellHeight: CGFloat = 80
    private var tableViewHeightConstraint: Constraint!
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header Section
    private let headerCard = UIView()
    private let titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Invoice Title"
        tf.font = .systemFont(ofSize: 24, weight: .bold)
        tf.textColor = .primaryText
        tf.backgroundColor = .clear
        return tf
    }()
    
    private let clientCard = UIView()
    private let clientLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "CLIENT"
        lbl.font = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = .secondaryText
        return lbl
    }()
    
    private let clientNameLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Add Client"
        lbl.font = .systemFont(ofSize: 17, weight: .medium)
        lbl.textColor = .primaryText
        return lbl
    }()
    
    private let clientChevron: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.tintColor = .iconSecondary
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private lazy var clientButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .clear
        return btn
    }()
    
    // Dates Section
    private let datesCard = UIView()
    
    private let dateContainer = UIView()
    private let dateHeaderLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "INVOICE DATE"
        lbl.font = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = .secondaryText
        return lbl
    }()
    private let datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .compact
        dp.tintColor = .primary
        return dp
    }()
    
    private let dueDateContainer = UIView()
    private let dueDateHeaderLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "DUE DATE"
        lbl.font = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = .secondaryText
        return lbl
    }()
    private let dueDatePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .compact
        dp.tintColor = .primary
        return dp
    }()
    
    // Items Section
    private let itemsHeaderLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "ITEMS"
        lbl.font = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = .secondaryText
        return lbl
    }()
    
    private lazy var itemsTableView: UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.register(InvoiceItemCell.self, forCellReuseIdentifier: InvoiceItemCell.reuseIdentifier)
        tv.isScrollEnabled = false
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        return tv
    }()
    
    private let addItemButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Add Item", for: .normal)
        btn.setTitleColor(.primary, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        
        let icon = UIImageView(image: UIImage(systemName: "plus.circle.fill"))
        icon.tintColor = .primary
        icon.contentMode = .scaleAspectFit
        btn.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 0)
        return btn
    }()
    
    // Summary Section
    private let summaryCard = UIView()
    
    private let subtotalContainer = UIView()
    private let subtotalTitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Subtotal"
        lbl.font = .systemFont(ofSize: 15, weight: .regular)
        lbl.textColor = .secondaryText
        return lbl
    }()
    private let subtotalAmountLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "$0.00"
        lbl.font = .systemFont(ofSize: 15, weight: .medium)
        lbl.textColor = .primaryText
        lbl.textAlignment = .right
        return lbl
    }()
    
    private let taxContainer = UIView()
    private let taxLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Vat"
        lbl.font = .systemFont(ofSize: 15, weight: .regular)
        lbl.textColor = .secondaryText
        return lbl
    }()
    private let taxTextField: UITextField = {
        let tf = UITextField()
        tf.text = "0"
        tf.font = .systemFont(ofSize: 15, weight: .medium)
        tf.textColor = .primaryText
        tf.textAlignment = .right
        tf.keyboardType = .decimalPad
        tf.backgroundColor = .clear
        return tf
    }()
    private let taxPercentLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "%"
        lbl.font = .systemFont(ofSize: 15, weight: .medium)
        lbl.textColor = .secondaryText
        return lbl
    }()
    
    private let discountContainer = UIView()
    private let discountLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Discount"
        lbl.font = .systemFont(ofSize: 15, weight: .regular)
        lbl.textColor = .secondaryText
        return lbl
    }()
    private let discountTextField: UITextField = {
        let tf = UITextField()
        tf.text = "0"
        tf.font = .systemFont(ofSize: 15, weight: .medium)
        tf.textColor = .primaryText
        tf.textAlignment = .right
        tf.keyboardType = .decimalPad
        tf.backgroundColor = .clear
        return tf
    }()
    private let discountDollarLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "$"
        lbl.font = .systemFont(ofSize: 15, weight: .medium)
        lbl.textColor = .secondaryText
        return lbl
    }()
    
    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = .border
        return v
    }()
    
    private let totalContainer = UIView()
    private let totalTitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Total"
        lbl.font = .systemFont(ofSize: 18, weight: .bold)
        lbl.textColor = .primaryText
        return lbl
    }()
    private let totalAmountLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "$0.00"
        lbl.font = .systemFont(ofSize: 24, weight: .bold)
        lbl.textColor = .primary
        lbl.textAlignment = .right
        return lbl
    }()
    
    // Save Button
    private lazy var saveButton: GradientButton = {
        let btn = GradientButton(type: .custom)
        btn.setTitle("Save Invoice", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.layer.cornerRadius = 12
        btn.clipsToBounds = true
        return btn
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
        title = "New Invoice"
        
        let dismissButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(dismissSelf))
        dismissButton.tintColor = .primary
        navigationItem.leftBarButtonItem = dismissButton
        
        clientButton.addTarget(self, action: #selector(selectClientTapped), for: .touchUpInside)
        addItemButton.addTarget(self, action: #selector(addItemTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveInvoiceTapped), for: .touchUpInside)
        
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        dueDatePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        titleTextField.delegate = self
        taxTextField.delegate = self
        discountTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(view)
        }
        
        setupHeaderCard()
        setupClientCard()
        setupDatesCard()
        setupItemsSection()
        setupSummaryCard()
        setupSaveButton()
        
        loadInvoiceData()
    }
    
    private func setupHeaderCard() {
        styleCard(headerCard)
        contentView.addSubview(headerCard)
        headerCard.addSubview(titleTextField)
        
        headerCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        titleTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }
    }
    
    private func setupClientCard() {
        styleCard(clientCard)
        contentView.addSubview(clientCard)
        clientCard.addSubview(clientLabel)
        clientCard.addSubview(clientNameLabel)
        clientCard.addSubview(clientChevron)
        clientCard.addSubview(clientButton)
        
        clientCard.snp.makeConstraints { make in
            make.top.equalTo(headerCard.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        clientLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        
        clientNameLabel.snp.makeConstraints { make in
            make.top.equalTo(clientLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
        
        clientChevron.snp.makeConstraints { make in
            make.centerY.equalTo(clientNameLabel)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(16)
        }
        
        clientButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupDatesCard() {
        styleCard(datesCard)
        contentView.addSubview(datesCard)
        
        datesCard.addSubview(dateContainer)
        datesCard.addSubview(dueDateContainer)
        
        dateContainer.addSubview(dateHeaderLabel)
        dateContainer.addSubview(datePicker)
        
        dueDateContainer.addSubview(dueDateHeaderLabel)
        dueDateContainer.addSubview(dueDatePicker)
        
        datesCard.snp.makeConstraints { make in
            make.top.equalTo(clientCard.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        dateContainer.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview().inset(16)
            make.width.equalToSuperview().multipliedBy(0.5).offset(-20)
        }
        
        dateHeaderLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        datePicker.snp.makeConstraints { make in
            make.top.equalTo(dateHeaderLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        dueDateContainer.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview().inset(16)
            make.width.equalToSuperview().multipliedBy(0.5).offset(-20)
        }
        
        dueDateHeaderLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        dueDatePicker.snp.makeConstraints { make in
            make.top.equalTo(dueDateHeaderLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func setupItemsSection() {
        contentView.addSubview(itemsHeaderLabel)
        contentView.addSubview(itemsTableView)
        contentView.addSubview(addItemButton)
        
        itemsHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(datesCard.snp.bottom).offset(24)
            make.leading.equalToSuperview().inset(16)
        }
        
        itemsTableView.snp.makeConstraints { make in
            make.top.equalTo(itemsHeaderLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            tableViewHeightConstraint = make.height.equalTo(0).constraint
        }
        
        addItemButton.snp.makeConstraints { make in
            make.top.equalTo(itemsTableView.snp.bottom).offset(12)
            make.leading.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
    }
    
    private func setupSummaryCard() {
        styleCard(summaryCard)
        contentView.addSubview(summaryCard)
        
        summaryCard.addSubview(subtotalContainer)
        summaryCard.addSubview(taxContainer)
        summaryCard.addSubview(discountContainer)
        summaryCard.addSubview(divider)
        summaryCard.addSubview(totalContainer)
        
        setupSummaryRow(subtotalContainer, titleLabel: subtotalTitleLabel, valueView: subtotalAmountLabel)
        setupTaxRow()
        setupDiscountRow()
        
        totalContainer.addSubview(totalTitleLabel)
        totalContainer.addSubview(totalAmountLabel)
        
        summaryCard.snp.makeConstraints { make in
            make.top.equalTo(addItemButton.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        subtotalContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(32)
        }
        
        taxContainer.snp.makeConstraints { make in
            make.top.equalTo(subtotalContainer.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(32)
        }
        
        discountContainer.snp.makeConstraints { make in
            make.top.equalTo(taxContainer.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(32)
        }
        
        divider.snp.makeConstraints { make in
            make.top.equalTo(discountContainer.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(1)
        }
        
        totalContainer.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        
        totalTitleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        totalAmountLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
    }
    
    private func setupSummaryRow(_ container: UIView, titleLabel: UILabel, valueView: UIView) {
        container.addSubview(titleLabel)
        container.addSubview(valueView)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        valueView.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
    }
    
    private func setupTaxRow() {
        taxContainer.addSubview(taxLabel)
        taxContainer.addSubview(taxTextField)
        taxContainer.addSubview(taxPercentLabel)
        
        taxLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        taxPercentLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
        
        taxTextField.snp.makeConstraints { make in
            make.trailing.equalTo(taxPercentLabel.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
    }
    
    private func setupDiscountRow() {
        discountContainer.addSubview(discountLabel)
        discountContainer.addSubview(discountDollarLabel)
        discountContainer.addSubview(discountTextField)
        
        discountLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        discountDollarLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
        
        discountTextField.snp.makeConstraints { make in
            make.trailing.equalTo(discountDollarLabel.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
            make.width.equalTo(80)
        }
    }
    
    private func setupSaveButton() {
        contentView.addSubview(saveButton)
        
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(summaryCard.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(56)
            make.bottom.equalToSuperview().inset(32)
        }
    }
    
    private func styleCard(_ card: UIView) {
        card.backgroundColor = .surface
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 8
        card.layer.shadowOpacity = 0.08
    }
    
    private func loadInvoiceData() {
        titleTextField.text = currentInvoice.invoiceTitle
        taxTextField.text = String(format: "%.1f", currentInvoice.taxRate * 100)
        discountTextField.text = String(format: "%.2f", currentInvoice.discount)
        datePicker.date = currentInvoice.invoiceDate
        dueDatePicker.date = currentInvoice.dueDate
        updateClientDisplay()
        updateTableViewHeight()
    }
    
    // MARK: - Helpers
    private func updateClientDisplay() {
        if let client = currentInvoice.client {
            clientNameLabel.text = client.clientName
            clientNameLabel.textColor = .primaryText
        } else {
            clientNameLabel.text = "Add Client"
            clientNameLabel.textColor = .secondaryText
        }
    }
    
    private func updateTableViewHeight() {
        let height = CGFloat(currentInvoice.items.count) * itemCellHeight
        tableViewHeightConstraint.update(offset: height)
        itemsTableView.reloadData()
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateInvoiceSummary() {
        let subtotal = currentInvoice.items.reduce(0) { $0 + $1.lineTotal }
        
        let taxRate = Double(taxTextField.text ?? "0") ?? 0.0
        currentInvoice.taxRate = max(0, taxRate / 100.0)
        
        let discount = Double(discountTextField.text ?? "0") ?? 0.0
        currentInvoice.discount = max(0, discount)
        
        let taxableSubtotal = max(0, subtotal - currentInvoice.discount)
        let taxAmount = taxableSubtotal * currentInvoice.taxRate
        let total = taxableSubtotal + taxAmount
        
        subtotalAmountLabel.text = subtotal.formatted(.currency(code: "USD"))
        totalAmountLabel.text = total.formatted(.currency(code: "USD"))
    }
    
    // MARK: - Actions
    @objc private func dismissSelf() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func endEditing() {
        view.endEditing(true)
    }
    
    @objc private func dateChanged() {
        currentInvoice.invoiceDate = datePicker.date
        currentInvoice.dueDate = dueDatePicker.date
    }
    
    @objc private func selectClientTapped() {
        print("Select Client Tapped")
        let clientToEdit = currentInvoice.client ?? Client()
        let newClientVC = NewClientViewController(client: clientToEdit)
        newClientVC.delegate = self
        let navController = UINavigationController(rootViewController: newClientVC)

        present(navController, animated: true)
    }
    
    @objc private func addItemTapped() {
        print("Add Item Tapped")
        let newItemVC = NewInvoiceItemViewController()
        newItemVC.delegate = self
        let navController = UINavigationController(rootViewController: newItemVC)
        present(navController, animated: true)
    }
    
    @objc private func saveInvoiceTapped() {
        currentInvoice.invoiceTitle = titleTextField.text
        
        print("--- Saving Invoice ---")
        print("Title: \(currentInvoice.invoiceTitle ?? "")")
        print("Client: \(currentInvoice.client?.clientName ?? "None")")
        print("Items: \(currentInvoice.items.count)")
        print("Tax: \(currentInvoice.taxRate * 100)%")
        print("Discount: $\(currentInvoice.discount)")
        print("Total: \(totalAmountLabel.text ?? "")")
        print("----------------------")
        
        // todo save to realm
        
        dismissSelf()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension NewInvoiceViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentInvoice.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InvoiceItemCell.reuseIdentifier, for: indexPath) as? InvoiceItemCell else {
            return UITableViewCell()
        }
        cell.configure(with: currentInvoice.items[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return itemCellHeight
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            currentInvoice.items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            updateTableViewHeight()
            updateInvoiceSummary()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("Edit item at \(indexPath.row)")
    }
}

// MARK: - UITextFieldDelegate
extension NewInvoiceViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
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

extension NewInvoiceViewController: NewClientViewControllerDelegate {
    func didSaveClient(_ client: Client) {
        print("Client saved: \(client)")
        currentInvoice.client = client
        clientNameLabel.text = client.clientName
        clientNameLabel.textColor = .primaryText
    }
}

extension NewInvoiceViewController: NewInvoiceItemViewControllerDelegate {
    func didSaveItem(_ item: InvoiceItem) {
        if let index = currentInvoice.items.firstIndex(where: { $0.id == item.id }) {
            currentInvoice.items[index] = item
        } else {
            currentInvoice.items.append(item)
        }

        updateTableViewHeight()
        updateInvoiceSummary()
    }
}
