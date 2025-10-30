import UIKit
import SnapKit

class InvoiceItemCell: UITableViewCell {
    static let reuseIdentifier = "InvoiceItemCell"
    
    // 💡 Добавляем titleLabel
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 18, weight: .bold) // Более крупный и жирный шрифт для заголовка
        lbl.textColor = .primaryText
        return lbl
    }()
    
    private let descriptionLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 16, weight: .semibold)
        lbl.textColor = .secondaryText // Сделаем этот текст немного менее заметным
        return lbl
    }()
    
    private let detailsLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 14, weight: .regular)
        lbl.textColor = .secondaryText
        return lbl
    }()
    
    private let totalLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 18, weight: .bold)
        lbl.textColor = .primary
        lbl.textAlignment = .right
        return lbl
    }()
    
    private let cardView = UIView()
    var cardTappedHandler: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .clear
        
        contentView.addSubview(cardView)
        cardView.backgroundColor = .surface
        cardView.layer.cornerRadius = 12
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.border.cgColor
        cardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cardTapped)))
        
        // 💡 Добавляем titleLabel в cardView
        cardView.addSubview(titleLabel)
        cardView.addSubview(descriptionLabel)
        cardView.addSubview(detailsLabel)
        cardView.addSubview(totalLabel)
        
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0))
        }
        
        // 💡 Ограничения для titleLabel
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
            make.trailing.equalTo(totalLabel.snp.leading).offset(-12)
        }
        
        // 💡 Изменяем ограничения для descriptionLabel (ставим его под titleLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2) // Небольшой отступ
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalTo(totalLabel.snp.leading).offset(-12)
        }
        
        // 💡 Изменяем ограничения для detailsLabel (ставим его под descriptionLabel)
        detailsLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
        
        totalLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(80)
        }
    }
    
    func configure(with item: InvoiceItem, currency: Currency) {
        titleLabel.text = item.name
        descriptionLabel.text = item.description
        detailsLabel.text = "\(item.quantity.formatted(.number.precision(.fractionLength(0...2)))) × \(item.unitPrice.formatted(.currency(code: currency.code)))"
        totalLabel.text = item.lineTotal.formatted(.currency(code: currency.code))
    }
    
    @objc private func cardTapped() {
        cardTappedHandler?()
    }
}
