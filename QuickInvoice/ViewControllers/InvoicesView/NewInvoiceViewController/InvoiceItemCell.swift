import UIKit
import SnapKit

class InvoiceItemCell: UITableViewCell {
    static let reuseIdentifier = "InvoiceItemCell"
    
    let descriptionLabel = UILabel()
    let quantityPriceLabel = UILabel() // Combined Qty and Price
    let totalLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        self.backgroundColor = .surface
        contentView.backgroundColor = .surface
        descriptionLabel.textColor = .primaryText
        quantityPriceLabel.textColor = .secondaryText
        totalLabel.textColor = .primaryText
        totalLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        
        [descriptionLabel, quantityPriceLabel, totalLabel].forEach { contentView.addSubview($0) }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(10)
        }
        
        quantityPriceLabel.snp.makeConstraints { make in
            make.leading.equalTo(descriptionLabel.snp.leading)
            make.bottom.equalToSuperview().inset(10)
        }
        
        totalLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(10)
        }
    }

    func configure(with item: InvoiceItem) {
        descriptionLabel.text = item.description
        quantityPriceLabel.text = "Qty: \(item.quantity.formatted(.number.precision(.fractionLength(0...2)))) @ \(item.unitPrice.formatted(.currency(code: "USD")))"
        totalLabel.text = item.lineTotal.formatted(.currency(code: "USD"))
    }
}
