import UIKit
import SnapKit

struct Client {
    var clientName: String?
}

struct Invoice {
    var invoiceTitle: String?
    var client: Client?
    var invoiceDate: String?
}

class InvoiceTableViewCell: UITableViewCell {
    
    // MARK: - Reuse Identifier
    static let reuseIdentifier = "invoiceTableViewCell"
    
    // MARK: - UI Elements
    
    // 1. Заголовок счета (крупный)
    public let invoiceTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = UIColor.primaryText // ✅ Замена .label
        return label
    }()
    
    // 2. Имя клиента (меньше и светлее)
    public let clientNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.secondaryText // ✅ Замена .secondaryLabel
        return label
    }()
    
    // 3. Дата счета (справа)
    public let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.tertiaryText // ✅ Замена .systemGray
        label.textAlignment = .right
        return label
    }()
    
    // Контейнер для меток слева (Title + Client)
    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [invoiceTitleLabel, clientNameLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.distribution = .fillEqually
        stack.spacing = 2
        return stack
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Убираем стандартную индикацию выделения
        self.selectionStyle = .none
        
        // Устанавливаем цвет фона ячейки
        self.backgroundColor = UIColor.surface // ✅ Используем Surface для фона ячейки
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        contentView.addSubview(textStackView)
        contentView.addSubview(dateLabel)
    }
    
    private func setupConstraints() {
        // Контейнер с текстом (Title и Client)
        textStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalTo(dateLabel.snp.leading).offset(-10) // До правой метки
            make.centerY.equalToSuperview()
        }
        
        // Метка с датой (справа)
        dateLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.width.equalTo(80) // Фиксированная ширина для даты
        }
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        invoiceTitleLabel.text = nil
        clientNameLabel.text = nil
        dateLabel.text = nil
    }
}
