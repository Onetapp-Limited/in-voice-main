import UIKit
import SnapKit
import PDFKit

// ВНЕШНИЙ КЛАСС ЯЧЕЙКИ COLLECTION VIEW
class TemplatePreviewCell: UICollectionViewCell {
    static let reuseIdentifier = "TemplatePreviewCell"
    
    // PDFView для отображения миниатюры
    private let pdfView: PDFView = {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePage
        view.displayDirection = .vertical
        view.backgroundColor = .white
        view.layer.cornerRadius = 6 // Уменьшен радиус для маленького превью
        view.layer.masksToBounds = true
        view.isUserInteractionEnabled = false
        // Устанавливаем скейл для лучшей видимости контента
        view.minScaleFactor = 0.5
        view.scaleFactor = 0.5
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(pdfView)
        contentView.addSubview(titleLabel)
        
        pdfView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(4)
            make.height.equalTo(80) // Меньшая высота
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(pdfView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(4)
        }
        
        contentView.layer.borderWidth = 2
        contentView.layer.cornerRadius = 8 // Общий радиус ячейки
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Функция для настройки ячейки
    func configure(with style: InvoiceTemplateStyle, pdfData: Data?, isSelected: Bool) {
        titleLabel.text = style.rawValue
        
        // Загрузка PDF данных в миниатюру
        if let data = pdfData, let document = PDFDocument(data: data) {
            pdfView.document = document
        } else {
            pdfView.document = nil
        }
        
        // Визуальное выделение выбранного стиля
        contentView.layer.borderColor = isSelected ? style.accentColor.cgColor : UIColor.clear.cgColor
        titleLabel.textColor = isSelected ? style.accentColor : UIColor.secondaryText
        
        // Добавляем легкую тень для превью
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowRadius = 3
        contentView.layer.shadowOffset = CGSize(width: 0, height: 1)
        contentView.layer.masksToBounds = false
    }
    
    override var isSelected: Bool {
        didSet {
            // При выделении обновляем внешний вид
            contentView.layer.borderColor = isSelected ? titleLabel.textColor.cgColor : UIColor.clear.cgColor
        }
    }
}
