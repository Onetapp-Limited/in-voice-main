import UIKit
import SnapKit

class SettingsCell: UITableViewCell {

    static let reuseIdentifier = "SettingsCell"

    // MARK: - UI Elements
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.primaryText
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return label
    }()

    private lazy var chevronIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: config))
        imageView.tintColor = UIColor.iconSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    
    private func setupUI() {
        // Общая логика фона и выбора (соответствует стилю InvoicesViewController)
        self.backgroundColor = .clear // Прозрачный фон для отображения background
        self.contentView.backgroundColor = UIColor.surface // Цвет "карточки"
        self.selectionStyle = .none
        
        // Закругление углов для эффекта "карточки"
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        contentView.addSubview(titleLabel)
        contentView.addSubview(chevronIcon)

        // Констрейнты
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        chevronIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(10)
        }
    }

    // Добавление отступов вокруг contentView для создания эффекта карточки, оторванной от фона
    override func layoutSubviews() {
        super.layoutSubviews()
        let inset: CGFloat = 8
        // Горизонтальный отступ 16, вертикальный 4 (8/2)
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: inset / 2, left: 16, bottom: inset / 2, right: 16))
    }

    // MARK: - Configuration
    
    func configure(with title: String) {
        titleLabel.text = title
    }
}
