import UIKit
import SnapKit
import PDFKit

class TemplatePreviewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "TemplatePreviewCell"
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.06
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowRadius = 4
        view.clipsToBounds = false
        return view
    }()
    
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor(white: 0.98, alpha: 1)
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let selectionOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        view.layer.cornerRadius = 4
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.systemBlue.cgColor
        view.isHidden = true
        return view
    }()
    
    private let checkmarkIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = 10
        imageView.isHidden = true
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 9, weight: .semibold)
        label.textColor = .primaryText
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    private let colorIndicator: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 1.5
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(thumbnailImageView)
        containerView.addSubview(selectionOverlay)
        containerView.addSubview(checkmarkIcon)
        containerView.addSubview(colorIndicator)
        containerView.addSubview(titleLabel)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(2)
        }
        
        thumbnailImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(4)
            make.height.equalTo(60)
        }
        
        selectionOverlay.snp.makeConstraints { make in
            make.edges.equalTo(thumbnailImageView)
        }
        
        checkmarkIcon.snp.makeConstraints { make in
            make.top.trailing.equalTo(thumbnailImageView).inset(3)
            make.size.equalTo(20)
        }
        
        colorIndicator.snp.makeConstraints { make in
            make.top.equalTo(thumbnailImageView.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.width.equalTo(20)
            make.height.equalTo(3)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(colorIndicator.snp.bottom).offset(3)
            make.leading.trailing.equalToSuperview().inset(2)
            make.bottom.equalToSuperview().inset(4)
        }
    }
    
    func configure(with style: InvoiceTemplateStyle, pdfData: Data, isSelected: Bool) {
        titleLabel.text = style.rawValue
        colorIndicator.backgroundColor = style.accentColor
        
        if let pdfDocument = PDFDocument(data: pdfData),
           let page = pdfDocument.page(at: 0) {
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 170))
            
            let thumbnail = renderer.image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: CGSize(width: 120, height: 170)))
                
                ctx.cgContext.translateBy(x: 0, y: 170)
                ctx.cgContext.scaleBy(x: 120 / pageRect.width, y: -170 / pageRect.height)
                
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            
            thumbnailImageView.image = thumbnail
        }
        
        selectionOverlay.isHidden = !isSelected
        checkmarkIcon.isHidden = !isSelected
        
        if isSelected {
            UIView.animate(withDuration: 0.15) {
                self.containerView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
                self.containerView.layer.shadowOpacity = 0.12
            }
        } else {
            UIView.animate(withDuration: 0.15) {
                self.containerView.transform = .identity
                self.containerView.layer.shadowOpacity = 0.06
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        selectionOverlay.isHidden = true
        checkmarkIcon.isHidden = true
        containerView.transform = .identity
    }
}
