import UIKit
import SnapKit

// Протокол для передачи данных обратно
protocol NewClientViewControllerDelegate: AnyObject {
    func didSaveClient(_ client: Client)
}

class NewClientViewController: UIViewController {

    weak var delegate: NewClientViewControllerDelegate?
    
    private var client: Client // Модель клиента, которую мы редактируем
    
    // MARK: - UI Elements
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var activeTextField: UITextField?
    
    // Поля ввода
    private let nameField = UITextField()
    private let emailField = UITextField()
    private let phoneField = UITextField()
    private let addressField = UITextField()
    private let idNumberField = UITextField()
    private let faxField = UITextField()
    
    // Элемент выбора типа клиента
    private lazy var typeSegmentedControl: UISegmentedControl = {
        let types = ClientType.allCases.map { $0.localized }
        let control = UISegmentedControl(items: types)
        control.selectedSegmentIndex = 0
        return control
    }()
    
    // MARK: - Initialization
    
    init(client: Client = Client()) {
        self.client = client
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
        loadClientData()
    }
    
    // MARK: - Setup
    
    private func setupModalPresentation() {
        // Настройка модального контроллера для отображения на пол-экрана
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()] // Разрешаем среднюю и полную высоту
            sheet.preferredCornerRadius = 20
        }
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Client Details"
        
        // Кнопка Save в правом верхнем углу
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))
        
        // Добавляем Scroll View
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        // Настройка Stack View
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width) // Важно для вертикального скроллинга
        }
        
        // Добавление полей
        addTextField(field: nameField, placeholder: "Client Name (Required)", delegate: self)
        addTextField(field: emailField, placeholder: "Email", keyboardType: .emailAddress, delegate: self)
        addTextField(field: phoneField, placeholder: "Phone Number", keyboardType: .phonePad, delegate: self)
        addTextField(field: addressField, placeholder: "Address", delegate: self)
        addTextField(field: idNumberField, placeholder: "ID Number", delegate: self)
        addTextField(field: faxField, placeholder: "Fax Number", keyboardType: .phonePad, delegate: self)
        
        stackView.addArrangedSubview(createLabel(text: "Client Type:"))
        stackView.addArrangedSubview(typeSegmentedControl)
        stackView.addArrangedSubview(UIView()) // Заполнитель, чтобы сдвинуть контент вверх
        
        // Скрытие клавиатуры по тапу на пустом месте
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
    
    private func addTextField(field: UITextField, placeholder: String, keyboardType: UIKeyboardType = .default, delegate: UITextFieldDelegate) {
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.keyboardType = keyboardType
        field.delegate = delegate
        field.snp.makeConstraints { $0.height.equalTo(44) }
        stackView.addArrangedSubview(field)
    }

    private func loadClientData() {
        nameField.text = client.clientName
        emailField.text = client.email
        phoneField.text = client.phoneNumber
        addressField.text = client.address
        idNumberField.text = client.idNumber
        faxField.text = client.faxNumber
        
        if let index = ClientType.allCases.firstIndex(of: client.clientType) {
            typeSegmentedControl.selectedSegmentIndex = index
        }
    }
    
    // MARK: - Actions

    @objc private func saveTapped() {
        // Проверка обязательного поля
        guard let name = nameField.text, !name.isEmpty else {
            showAlert(title: "Required Field Missing", message: "Client Name is required.")
            return
        }
        
        // Обновление модели
        client.clientName = name
        client.email = emailField.text
        client.phoneNumber = phoneField.text
        client.address = addressField.text
        client.idNumber = idNumberField.text
        client.faxNumber = faxField.text
        
        let selectedType = ClientType.allCases[typeSegmentedControl.selectedSegmentIndex]
        client.clientType = selectedType

        // Передача обновленного клиента обратно
        delegate?.didSaveClient(client)
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
        
        // Рассчитываем область, которую нужно показать
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
}

// MARK: - Text Field Delegate

extension NewClientViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeTextField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeTextField = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // При нажатии Return переходим к следующему полю или скрываем клавиатуру
        if let nextField = stackView.viewWithTag(textField.tag + 1) {
            nextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
