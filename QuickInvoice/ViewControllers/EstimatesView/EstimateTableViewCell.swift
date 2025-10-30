import UIKit
import SnapKit

class EstimateTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "EstimateTableViewCell"
    
    // MARK: - UI Elements
    
    // 1. Контейнер для первой буквы (аватар)
    private lazy var initialsView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.secondary.withAlphaComponent(0.3) // Яркий акцентный фон
        view.layer.cornerRadius = 25 // Делаем круглым (высота 60 / 2)
        view.clipsToBounds = true
        return view
    }()
    
    // 2. Лейбл для первой буквы
    private lazy var initialsLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    // 3. Лейбл для тайтла (название сметы)
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = UIColor.primaryText // Ваш кастомный цвет
        label.numberOfLines = 1
        return label
    }()
    
    // 4. Лейбл для общей суммы
    private lazy var totalAmountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .heavy)
        label.textColor = UIColor.accent // Выделяем сумму акцентным цветом
        label.textAlignment = .right
        return label
    }()
    
    // 5. Контейнер для основного содержимого (для отступов)
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.surface // Ваш кастомный цвет
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Настройки ячейки
        selectionStyle = .none
        backgroundColor = UIColor.background // Фон ячейки соответствует фону контроллера
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Добавляем отступ между ячейками
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Добавляем контейнер с отступами
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 1. Аватар-контейнер
        containerView.addSubview(initialsView)
        initialsView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(50) // Большая круглая иконка
        }
        
        // 2. Буква внутри аватара
        initialsView.addSubview(initialsLabel)
        initialsLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        // 4. Общая сумма (прижата к трейлингу)
        containerView.addSubview(totalAmountLabel)
        totalAmountLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            // Даем ширину, чтобы избежать наложения, но не фиксируем жестко
            make.width.lessThanOrEqualTo(120)
        }
        
        // 3. Тайтл (между аватаром и суммой)
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(initialsView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            // Ограничиваем трейлинг, чтобы не налезать на сумму
            make.trailing.equalTo(totalAmountLabel.snp.leading).offset(-12)
        }
    }
    
    // MARK: - Configuration
    
    func configure(with estimate: Estimate) {
        // Настройка Аватара: берем первую букву тайтла
        let initial = estimate.estimateTitle?.first.map { String($0).uppercased() } ?? "?"
        initialsLabel.text = initial
        
        // Настройка Тайтла
        titleLabel.text = estimate.estimateTitle ?? "Untitled Estimate"
        
        // Настройка Общей суммы
        // Используем grandTotal, который вы рассчитали, и currencySymbol
        let formattedTotal = String(format: "%.2f", estimate.grandTotal)
        totalAmountLabel.text = "\(estimate.currencySymbol)\(formattedTotal)"
        
        // Дополнительный визуальный эффект: если сметы "в черновике", можно выделить
        if estimate.status == .draft {
             containerView.layer.borderWidth = 1.0
             containerView.layer.borderColor = UIColor.border.cgColor
        } else {
             containerView.layer.borderWidth = 0
             containerView.layer.borderColor = nil
        }
    }
}
