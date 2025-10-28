import UIKit
import SnapKit

// Протокол для передачи данных обратно
protocol NewInvoiceItemViewControllerDelegate: AnyObject {
    func didSaveItem(_ item: InvoiceItem)
}

class NewInvoiceItemViewController: UIViewController, UITextFieldDelegate {

    weak var delegate: NewInvoiceItemViewControllerDelegate?
    
    private var item: InvoiceItem // Модель итема, которую мы редактируем
    
    // MARK: - UI Elements
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var activeTextField: UITextField?
    
    // Поля ввода
    private let nameField = UITextField()
    private let descriptionField = UITextField()
    private let priceField = UITextField()
    private let quantityField = UITextField()
    private let discountField = UITextField() // Оставляем, как в исходном коде, но не используем в UI
    
    // Элементы управления
    
    private lazy var discountSegmentedControl: UISegmentedControl = {
        let types = DiscountType.allCases.map { $0.localized }
        let control = UISegmentedControl(items: types)
        control.selectedSegmentIndex = 1 // По умолчанию "Percentage"
        return control
    }()
    
    private lazy var unitSegmentedControl: UISegmentedControl = {
        let types = UnitType.allCases.map { $0.localized }
        let control = UISegmentedControl(items: types)
        control.selectedSegmentIndex = 2 // По умолчанию "Item"
        return control
    }()
    
    private lazy var taxableSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = true
        return toggle
    }()
    
    // MARK: - Initialization
    
    init(item: InvoiceItem = InvoiceItem()) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupModalPresentation()
        setupUI()
        setupKeyboardHandling()
        loadItemData()
    }
    
    // MARK: - Setup
    
    private func setupModalPresentation() {
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.preferredCornerRadius = 20
        }
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Item Details"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))
        
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }
        
        // --- Добавление полей ---
        addTextField(field: nameField, placeholder: "Item Name (Required)", delegate: self)
        addTextField(field: descriptionField, placeholder: "Description", delegate: self)
        
        // Цена и Количество (Теперь с лейблами сверху)
        addLabeledTextField(field: priceField, labelText: "Unit Price:", keyboardType: .decimalPad, delegate: self)
        addLabeledTextField(field: quantityField, labelText: "Quantity:", keyboardType: .decimalPad, delegate: self)
        
        // Тип единицы измерения (Days/Hours/Item)
        stackView.addArrangedSubview(createLabel(text: "Unit Type:"))
        stackView.addArrangedSubview(unitSegmentedControl)
        
        // Скидка: ТОЛЬКО ТИП (убираем текстовое поле)
        stackView.addArrangedSubview(createLabel(text: "Discount Type:")) // Изменяем заголовок для ясности
        stackView.addArrangedSubview(discountSegmentedControl)
        // **УДАЛЕНО:** addTextField(field: discountField, placeholder: "Value (e.g., 10 or 15.00)", keyboardType: .decimalPad, delegate: self)
        
        // Taxable Toggle
        stackView.addArrangedSubview(createToggleRow(label: "Taxable", toggle: taxableSwitch))

        stackView.addArrangedSubview(UIView()) // Заполнитель
        
        // Скрытие клавиатуры
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        return label
    }
    
    private func createToggleRow(label text: String, toggle: UISwitch) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        
        let label = createLabel(text: text)
        stack.addArrangedSubview(label)
        
        // Добавляем spacer, чтобы тогл прижался вправо
        let spacer = UIView()
        stack.addArrangedSubview(spacer)
        
        stack.addArrangedSubview(toggle)
        return stack
    }
    
    // Вспомогательная функция для полей, где нужен только placeholder и нет лейбла (Name, Description)
    private func addTextField(field: UITextField, placeholder: String, keyboardType: UIKeyboardType = .default, delegate: UITextFieldDelegate) {
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.keyboardType = keyboardType
        field.delegate = delegate
        field.tag = stackView.arrangedSubviews.count // Для логики textFieldShouldReturn
        field.returnKeyType = .next
        field.snp.makeConstraints { $0.height.equalTo(44) }
        stackView.addArrangedSubview(field)
    }

    // Вспомогательная функция для полей с лейблом сверху (Unit Price, Quantity)
    private func addLabeledTextField(field: UITextField, labelText: String, keyboardType: UIKeyboardType = .default, delegate: UITextFieldDelegate) {
        
        // Добавляем заголовок (лейбл)
        stackView.addArrangedSubview(createLabel(text: labelText))
        
        // Настраиваем само поле
        field.placeholder = labelText.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        field.borderStyle = .roundedRect
        field.keyboardType = keyboardType
        field.delegate = delegate
        
        // Важно: тег поля должен быть после добавления лейбла
        field.tag = stackView.arrangedSubviews.count
        field.returnKeyType = .next
        field.snp.makeConstraints { $0.height.equalTo(44) }
        
        // Добавляем поле ввода
        stackView.addArrangedSubview(field)
    }


    private func loadItemData() {
        nameField.text = item.name
        descriptionField.text = item.description
        priceField.text = String(format: "%.2f", item.unitPrice)
        quantityField.text = String(format: "%.2f", item.quantity)
        // **УДАЛЕНО:** discountField.text = String(format: "%.2f", item.discountValue)
        taxableSwitch.isOn = item.isTaxable
        
        if let unitIndex = UnitType.allCases.firstIndex(of: item.unitType) {
            unitSegmentedControl.selectedSegmentIndex = unitIndex
        }
        if let discountIndex = DiscountType.allCases.firstIndex(of: item.discountType) {
            discountSegmentedControl.selectedSegmentIndex = discountIndex
        }
    }
    
    // MARK: - Actions

    @objc private func saveTapped() {
        guard let name = nameField.text, !name.isEmpty else {
            showAlert(title: "Required Field Missing", message: "Item Name is required.")
            return
        }
        
        // Обновление модели
        item.name = name
        item.description = descriptionField.text ?? ""
        
        // Преобразование числовых полей
        item.unitPrice = Double(priceField.text?.replacingOccurrences(of: ",", with: ".") ?? "0") ?? 0.0
        item.quantity = Double(quantityField.text?.replacingOccurrences(of: ",", with: ".") ?? "1") ?? 1.0
        // Оставляем эту строку для сохранения discountValue, хотя поле ввода удалено
//         item.discountValue = Double(discountField.text?.replacingOccurrences(of: ",", with: ".") ?? "0") ?? 0.0
        
        item.isTaxable = taxableSwitch.isOn
        item.discountType = DiscountType.allCases[discountSegmentedControl.selectedSegmentIndex]
        item.unitType = UnitType.allCases[unitSegmentedControl.selectedSegmentIndex]

        // Передача обновленного итема обратно
        delegate?.didSaveItem(item)
        dismiss(animated: true, completion: nil)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Keyboard Handling Logic
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowHandler), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideHandler), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func keyboardWillShowHandler(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let activeTextField = activeTextField
        else { return }
        
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        
        var aRect = self.view.frame
        aRect.size.height -= keyboardFrame.height
        
        let fieldFrameInView = activeTextField.convert(activeTextField.bounds, to: self.view)

        if !aRect.contains(fieldFrameInView.origin) {
            let scrollPoint = CGPoint(x: 0, y: fieldFrameInView.origin.y - keyboardFrame.height / 2)
            scrollView.setContentOffset(scrollPoint, animated: true)
        }
    }
    
    @objc func keyboardWillHideHandler(notification: NSNotification) {
        let contentInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    @objc func endEditing() {
        view.endEditing(true)
    }
    
    // MARK: - Text Field Delegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeTextField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeTextField = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Переходим к следующему полю, используя tag
        if let nextField = stackView.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
