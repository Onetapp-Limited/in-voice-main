import UIKit
import SnapKit

class InvoiceTableViewCell: UITableViewCell {
    static let reuseIdentifier = "InvoiceTableViewCell"
    
    // UI Elements
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    
    // Левый блок
    let invoiceTitleLabel = UILabel()
    let clientNameLabel = UILabel()
    
    // Правый блок
    let totalAmountLabel = UILabel()
    let dueDateLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        self.backgroundColor = .background
        self.selectionStyle = .none
        
        // 1. Контейнер для карточного стиля
        containerView.backgroundColor = .surface
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        containerView.layer.shadowOpacity = 1
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        contentView.addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6) // Отступы между ячейками
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        // 2. Иконка
        iconImageView.image = UIImage(systemName: "doc.text.fill")
        iconImageView.tintColor = .accent
        iconImageView.contentMode = .scaleAspectFit
        containerView.addSubview(iconImageView)
        
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        
        // 3. Левый стек (Title и Client Name)
        invoiceTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        invoiceTitleLabel.textColor = .primaryText
        clientNameLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        clientNameLabel.textColor = .secondaryText
        
        let leftStack = UIStackView(arrangedSubviews: [invoiceTitleLabel, clientNameLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 2
        containerView.addSubview(leftStack)
        
        leftStack.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.45) // Фиксируем ширину для ровности
        }
        
        // 4. Правый стек (Total Amount и Due Date)
        totalAmountLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        totalAmountLabel.textColor = .success // Выделяем сумму зеленым
        totalAmountLabel.textAlignment = .right
        
        dueDateLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        dueDateLabel.textColor = .secondaryText
        dueDateLabel.textAlignment = .right
        
        let rightStack = UIStackView(arrangedSubviews: [totalAmountLabel, dueDateLabel])
        rightStack.axis = .vertical
        rightStack.spacing = 2
        containerView.addSubview(rightStack)
        
        rightStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.leading.equalTo(leftStack.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
    }
    
    // Метод для настройки данных ячейки
    func configure(with invoice: Invoice) {
        invoiceTitleLabel.text = invoice.invoiceTitle ?? "Untitled Invoice"
        clientNameLabel.text = invoice.client?.clientName ?? "No Client"
        totalAmountLabel.text = invoice.totalAmount // Предполагается, что уже отформатирован ($1,234.00)
        dueDateLabel.text = "Due: \(DateFormatter.shortDate.string(from: invoice.dueDate))"
        
        // Стиль для статуса: Если просрочен, меняем цвет
        if invoice.dueDate < Date() && invoice.status != "Paid" {
            dueDateLabel.textColor = .systemRed
        } else {
            dueDateLabel.textColor = .secondaryText
        }
        
        // Стиль для суммы: Если статус Paid, цвет успеха
        if invoice.status == "Paid" {
            totalAmountLabel.textColor = .success
        } else {
            totalAmountLabel.textColor = .warning // Если не оплачен, предупреждающий цвет
        }
    }
}
