import UIKit
import SnapKit

class ClientTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "ClientTableViewCell"
    
    // MARK: - UI Elements
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        // Системная иконка "аватарка одного человека"
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = UIColor.accent // Ваш акцентный цвет для иконки
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = UIColor.primaryText
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var typeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.secondaryText // Приглушенный цвет
        label.textAlignment = .right
        return label
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.surface // Ваш кастомный цвет фона
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        backgroundColor = UIColor.background
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Добавляем отступ между ячейками
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(typeLabel)
        
        // 1. Иконка
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(40) // Меньше, чем аватарка естимейта
        }
        
        // 3. Тип клиента (прижат к трейлингу)
        typeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.lessThanOrEqualTo(100)
        }
        
        // 2. Имя клиента (между иконкой и типом)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(typeLabel.snp.leading).offset(-12)
        }
    }
    
    // MARK: - Configuration
    
    func configure(with client: Client) {
        nameLabel.text = client.clientName ?? "No Name"
        typeLabel.text = client.clientType.rawValue
    }
}
