import UIKit
import SnapKit

class ClientSalesCell: UITableViewCell {
    
    static let reuseIdentifier = "ClientSalesCell"
    
    private let clientLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .primaryText
        return label
    }()
    
    private let earnedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryText
        return label
    }()
    
    private let statusBadge: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        statusBadge.addSubview(statusLabel)
        
        contentView.addSubview(clientLabel)
        contentView.addSubview(earnedLabel)
        contentView.addSubview(statusBadge)
        
        clientLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(10)
        }
        
        earnedLabel.snp.makeConstraints { make in
            make.leading.equalTo(clientLabel)
            make.top.equalTo(clientLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        statusBadge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(70)
            make.height.equalTo(24)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(clientName: String, earned: Double, paid: Double) {
        clientLabel.text = clientName
        earnedLabel.text = "$\(Int(earned).formattedWithSeparator) earned"
        
        let isPaid = earned - paid <= 0.0
        statusLabel.text = isPaid ? "Paid" : "Unpaid"
        statusLabel.textColor = isPaid ? .success : .warning
        statusBadge.backgroundColor = isPaid ? UIColor.success.withAlphaComponent(0.15) : UIColor.warning.withAlphaComponent(0.15)
    }
}
