import UIKit
import SnapKit

class HomeCollectionViewCell: UICollectionViewCell {
    
    // MARK: - UI Elements
    
    // 1. ImageView для отображения иконки (публичный для доступа из HomeViewController)
    public let imageIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.primary // ✅ Замена .systemBlue
        return imageView
    }()
    
    // 2. Label для отображения текста действия (публичный для доступа из HomeViewController)
    public let actionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = UIColor.primaryText // ✅ Замена .label
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    // Контейнер (StackView) для вертикального расположения элементов
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [imageIcon, actionLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.distribution = .fillProportionally
        stack.spacing = 8
        return stack
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        styleCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        contentView.addSubview(stackView)
    }
    
    private func setupConstraints() {
        // Центрируем StackView в ячейке, используя SnapKit
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.height.lessThanOrEqualToSuperview().inset(10)
        }
        
        // Фиксируем размер иконки
        imageIcon.snp.makeConstraints { make in
            make.width.height.equalTo(40)
        }
    }
    
    private func styleCell() {
        // Базовые стили для contentView
        contentView.backgroundColor = UIColor.surface // ✅ Замена .systemGray6
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
    }
    
    // MARK: - Public Methods
    
    // Функция для обновления тени (согласно исходному коду)
    public func updateShadow() {
        layer.shadowColor = UIColor.black.cgColor // Оставляем черный цвет для тени, это стандарт
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.masksToBounds = false
        layer.cornerRadius = 12
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        actionLabel.text = nil
        imageIcon.image = nil
    }
}
