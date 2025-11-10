import UIKit
import SnapKit

class CompanyInfoViewController: UIViewController {
    
    // MARK: - Properties
    var companyInfo: CompanyInfo! // Будет инициализирована при переходе
    var didSaveCompanyInfo: ((CompanyInfo) -> Void)?
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let nameField = CompanyInputField(title: "Company Name", placeholder: "My Company Inc.")
    private let streetField = CompanyInputField(title: "Street Address", placeholder: "123 Business Blvd, Suite 400")
    private let cityStateZipField = CompanyInputField(title: "City, State, Zip", placeholder: "City, State, 10001")
    private let emailField = CompanyInputField(title: "Contact Email", placeholder: "contact@mycompany.com", keyboardType: .emailAddress)
    
    private lazy var stackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [nameField, streetField, cityStateZipField, emailField])
        sv.axis = .vertical
        sv.spacing = 24
        return sv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewController()
        setupUI()
        loadInitialData()
    }
    
    // MARK: - Setup
    private func setupViewController() {
        view.backgroundColor = .background
        title = "Your Company Details"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(dismissSelf))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))
        
        // Устанавливаем делегатов, чтобы можно было скрыть клавиатуру
        nameField.textField.delegate = self
        streetField.textField.delegate = self
        cityStateZipField.textField.delegate = self
        emailField.textField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(view)
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    private func loadInitialData() {
        nameField.textField.text = companyInfo.name
        streetField.textField.text = companyInfo.street
        cityStateZipField.textField.text = companyInfo.cityStateZip
        emailField.textField.text = companyInfo.email
    }
    
    // MARK: - Actions
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        // 1. Собираем данные из полей
        var updatedInfo = CompanyInfo(
            name: nameField.textField.text ?? "My Company",
            street: streetField.textField.text ?? "",
            cityStateZip: cityStateZipField.textField.text ?? "",
            email: emailField.textField.text ?? ""
        )
        
        // 2. Вызываем обработчик сохранения
        didSaveCompanyInfo?(updatedInfo)
        
        // 3. Закрываем контроллер
        dismiss(animated: true)
    }
    
    @objc private func endEditing() {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate
extension CompanyInfoViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Custom Input Field (Вспомогательный класс для чистоты кода)
private class CompanyInputField: UIView {
    let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 14, weight: .medium)
        lbl.textColor = .secondaryText
        return lbl
    }()
    
    let textField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 17, weight: .regular)
        tf.textColor = .primaryText
        tf.borderStyle = .roundedRect
        tf.backgroundColor = .surface
        tf.returnKeyType = .done
        return tf
    }()
    
    init(title: String, placeholder: String, keyboardType: UIKeyboardType = .default) {
        super.init(frame: .zero)
        titleLabel.text = title
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(textField)
        
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        textField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
            make.bottom.equalToSuperview() // Чтобы контейнер имел правильную высоту
        }
    }
}
