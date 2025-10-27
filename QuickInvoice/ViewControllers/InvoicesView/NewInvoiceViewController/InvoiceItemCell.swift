import UIKit
import SnapKit


class InvoiceItemCell: UITableViewCell {
    static let reuseIdentifier = "InvoiceItemCell"
    
    private let cardView = UIView()
    private let descriptionLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 16, weight: .semibold)
        lbl.textColor = .primaryText
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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(cardView)
        cardView.backgroundColor = .surface
        cardView.layer.cornerRadius = 12
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.border.cgColor
        
        cardView.addSubview(descriptionLabel)
        cardView.addSubview(detailsLabel)
        cardView.addSubview(totalLabel)
        
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0))
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
            make.trailing.equalTo(totalLabel.snp.leading).offset(-12)
        }
        
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
    
    func configure(with item: InvoiceItem) {
        descriptionLabel.text = item.description
        detailsLabel.text = "\(item.quantity.formatted(.number.precision(.fractionLength(0...2)))) × \(item.unitPrice.formatted(.currency(code: "USD")))"
        totalLabel.text = item.lineTotal.formatted(.currency(code: "USD"))
    }
}
