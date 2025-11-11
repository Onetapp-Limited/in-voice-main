import UIKit
import SnapKit
import PDFKit
import MessageUI

// MARK: - Template Preview Cell
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

class InvoiceDetailPDFViewController: UIViewController {
    
    var isEstimate: Bool = false
    var invoice: Invoice?
    private let pdfView = PDFView()
    
    private var currentStyle: InvoiceTemplateStyle = .modern {
        didSet {
            generateAndLoadPDF()
            styleCollectionView.reloadData()
        }
    }
    
    private var estimateService: EstimateService? {
        do {
            return try EstimateService()
        } catch {
            print("Failed to initialize EstimateService: \(error)")
            return nil
        }
    }
    
    private var invoiceService: InvoiceService? {
        do {
            return try InvoiceService()
        } catch {
            print("Failed to initialize InvoiceService: \(error)")
            return nil
        }
    }
    
    enum SummarySymbolType {
        case currency
        case percent
    }
    
    private let templateHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose Template"
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .primaryText
        return label
    }()
    
    private lazy var styleCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 100)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TemplatePreviewCell.self, forCellWithReuseIdentifier: TemplatePreviewCell.reuseIdentifier)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    private let templateContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray.withAlphaComponent(0.04)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private lazy var convertButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Convert to Invoice"
        config.image = UIImage(systemName: "arrow.right.circle.fill")
        config.imagePadding = 10
        config.baseBackgroundColor = .secondary
        config.baseForegroundColor = .white
        config.buttonSize = .large
        config.cornerStyle = .large
        
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.convertButtonTapped()
        })
        button.layer.shadowColor = UIColor.black.withAlphaComponent(0.15).cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 8
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        return button
    }()
    
    private lazy var sendButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = isEstimate ? "Share Estimate" : "Share Invoice"
        config.image = UIImage(systemName: "square.and.arrow.up.fill")
        config.imagePadding = 10
        config.baseBackgroundColor = .primary
        config.baseForegroundColor = .white
        config.buttonSize = .large
        config.cornerStyle = .large
        
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.sendButtonTapped()
        })
        button.layer.shadowColor = UIColor.primary.cgColor
        button.layer.shadowOpacity = 0.4
        button.layer.shadowRadius = 10
        button.layer.shadowOffset = CGSize(width: 0, height: 5)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard invoice != nil else {
            print("Error: Invoice model not set.")
            dismiss(animated: true)
            return
        }
        
        setupUI()
        generateAndLoadPDF()
        
        DispatchQueue.main.async {
            self.styleCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: [])
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupUI() {
        view.backgroundColor = .background
        
        title = isEstimate ? "Estimate Preview" : (invoice?.invoiceTitle ?? "Invoice Preview")
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "pencil.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(editTapped)
        )
        
        view.addSubview(pdfView)
        view.addSubview(templateContainerView)
        templateContainerView.addSubview(templateHeaderLabel)
        templateContainerView.addSubview(styleCollectionView)
        view.addSubview(sendButton)
        
        var topOfButtonsConstraint: ConstraintRelatableTarget = templateContainerView.snp.top
        
        if isEstimate {
            view.addSubview(convertButton)
            
            convertButton.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(20)
                make.bottom.equalTo(sendButton.snp.top).offset(-12)
                make.height.equalTo(54)
            }
            
            topOfButtonsConstraint = convertButton.snp.top
        } else {
            topOfButtonsConstraint = sendButton.snp.top
        }
        
        templateContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(topOfButtonsConstraint).offset(-16)
            make.height.equalTo(130)
        }
        
        templateHeaderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(16)
        }
        
        styleCollectionView.snp.makeConstraints { make in
            make.top.equalTo(templateHeaderLabel.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        sendButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(54)
        }
        
        pdfView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(templateContainerView.snp.top).offset(-16)
        }
        
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        pdfView.displayMode = .singlePageContinuous
        pdfView.backgroundColor = .white
        pdfView.layer.cornerRadius = 12
        pdfView.clipsToBounds = true
        pdfView.layer.shadowColor = UIColor.black.cgColor
        pdfView.layer.shadowOpacity = 0.1
        pdfView.layer.shadowRadius = 10
        pdfView.layer.shadowOffset = CGSize(width: 0, height: 3)
    }
    
    private func generateAndLoadPDF() {
        guard let invoice = invoice else { return }
        let pdfData = generatePDF(for: invoice, style: currentStyle)
        
        if let document = PDFDocument(data: pdfData) {
            pdfView.document = document
        } else {
            let alert = UIAlertController(title: "Error", message: "Could not generate PDF document.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    private func generatePDF(for invoice: Invoice, style: InvoiceTemplateStyle) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            
            let margin: CGFloat = 40
            var currentY: CGFloat = margin
            
            switch style {
            case .modern:
                currentY = drawModernHeader(pageRect: pageRect, currentY: currentY, margin: margin, invoice: invoice, style: style)
            case .classic:
                currentY = drawClassicHeader(pageRect: pageRect, currentY: currentY, margin: margin, invoice: invoice, style: style)
            case .minimal:
                currentY = drawMinimalHeader(pageRect: pageRect, currentY: currentY, margin: margin, invoice: invoice, style: style)
            case .vibrant:
                currentY = drawVibrantHeader(pageRect: pageRect, currentY: currentY, margin: margin, invoice: invoice, style: style)
            case .boxed:
                currentY = drawBoxedHeader(pageRect: pageRect, currentY: currentY, margin: margin, invoice: invoice, style: style)
            default:
                currentY = drawHeader(pageRect: pageRect, currentY: currentY, margin: margin, invoice: invoice, style: style)
            }
            
            currentY = drawCompanyInfo(pageRect: pageRect, currentY: currentY + 15, margin: margin, invoice: invoice, style: style)
            currentY = drawClientInfo(pageRect: pageRect, currentY: currentY + 25, margin: margin, invoice: invoice, style: style)
            currentY = drawItemsTable(pageRect: pageRect, currentY: currentY + 25, margin: margin, invoice: invoice, style: style)
            currentY = drawSummary(pageRect: pageRect, currentY: currentY + 20, margin: margin, invoice: invoice, style: style)
            _ = drawFooter(pageRect: pageRect, currentY: 800, margin: margin, style: style, isEstimate: isEstimate)
        }
        
        return pdfData
    }
    
    private func drawHeader(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice, style: InvoiceTemplateStyle) -> CGFloat {
        var y = currentY
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 28, isBold: true),
            .foregroundColor: style.accentColor
        ]
        let titleText = (invoice.invoiceTitle ?? "INVOICE").uppercased()
        titleText.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttributes)
        
        let idText = "#\(invoice.id.uuidString.prefix(8).uppercased())"
        let idAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 20, isBold: true),
            .foregroundColor: UIColor.secondaryText
        ]
        
        let idSize = idText.size(withAttributes: idAttributes)
        let idRect = CGRect(x: pageRect.width - margin - idSize.width, y: y + 8, width: idSize.width, height: idSize.height)
        idText.draw(in: idRect, withAttributes: idAttributes)
        
        y += 38
        
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin, y: y))
        line.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
        
        if style == .classic || style == .minimal {
            UIColor.systemGray.setStroke()
            line.lineWidth = 1
        } else {
            style.accentColor.setStroke()
            line.lineWidth = 2.5
        }
        line.stroke()
        
        return y + 10
    }
    
    private func drawModernHeader(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice, style: InvoiceTemplateStyle) -> CGFloat {
        var y = currentY
        
        let sidebarRect = CGRect(x: 0, y: 0, width: 10, height: pageRect.height)
        style.accentColor.setFill()
        UIRectFill(sidebarRect)
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 26, isBold: true),
            .foregroundColor: UIColor.white
        ]
        
        let titleText = (invoice.invoiceTitle ?? "INVOICE").uppercased()
        let titleSize = titleText.size(withAttributes: titleAttributes)
        
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.translateBy(x: 60, y: 120)
        context?.rotate(by: -CGFloat.pi / 2)
        titleText.draw(at: CGPoint(x: -titleSize.width / 2, y: -titleSize.height / 2), withAttributes: titleAttributes)
        context?.restoreGState()
        
        let contentX = margin + 100
        
        let idText = "#\(String(invoice.id.uuidString.prefix(8)).uppercased())"
        let idAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 20, isBold: true),
            .foregroundColor: UIColor.primaryText
        ]
        idText.draw(at: CGPoint(x: contentX, y: y), withAttributes: idAttributes)
        
        return y + 25
    }
    
    private func drawClassicHeader(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice, style: InvoiceTemplateStyle) -> CGFloat {
        var y = currentY
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 32, isBold: true),
            .foregroundColor: style.accentColor
        ]
        
        let titleText = (invoice.invoiceTitle ?? "INVOICE").uppercased()
        let titleSize = titleText.size(withAttributes: titleAttributes)
        let titleX = (pageRect.width - titleSize.width) / 2
        
        titleText.draw(at: CGPoint(x: titleX, y: y), withAttributes: titleAttributes)
        y += 45
        
        let lineY = y
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        
        style.accentColor.setStroke()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin + 80, y: lineY))
        line.addLine(to: CGPoint(x: pageRect.width - margin - 80, y: lineY))
        line.lineWidth = 1.5
        line.stroke()
        
        context?.restoreGState()
        
        y += 15
        
        let idText = "No. \(String(invoice.id.uuidString.prefix(8)).uppercased())"
        let idAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 20),
            .foregroundColor: UIColor.secondaryText
        ]
        let idSize = idText.size(withAttributes: idAttributes)
        let idX = (pageRect.width - idSize.width) / 2
        idText.draw(at: CGPoint(x: idX, y: y), withAttributes: idAttributes)
        
        return y + 30
    }
    
    private func drawMinimalHeader(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice, style: InvoiceTemplateStyle) -> CGFloat {
        var y = currentY + 10
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 26, isBold: true),
            .foregroundColor: style.accentColor
        ]
        
        let titleText = (invoice.invoiceTitle ?? "INVOICE").uppercased()
        titleText.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttributes)
        
        y += 30
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin, y: y))
        line.addLine(to: CGPoint(x: margin + 80, y: y))
        UIColor.systemGray.withAlphaComponent(0.3).setStroke()
        line.lineWidth = 1
        line.stroke()
        
        y += 12
        
        let idText = "#\(String(invoice.id.uuidString.prefix(6)).uppercased())"
        let idAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 16),
            .foregroundColor: UIColor.secondaryText
        ]
        idText.draw(at: CGPoint(x: margin, y: y), withAttributes: idAttributes)
        
        return y + 25
    }
    
    private func drawVibrantHeader(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice, style: InvoiceTemplateStyle) -> CGFloat {
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: pageRect.width, y: 0))
        path.addLine(to: CGPoint(x: pageRect.width, y: 100))
        path.addLine(to: CGPoint(x: 0, y: 70))
        path.close()
        
        style.accentColor.setFill()
        path.fill()
        
        context?.restoreGState()
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 28, isBold: true),
            .foregroundColor: UIColor.white
        ]
        
        let titleText = (invoice.invoiceTitle ?? "INVOICE").uppercased()
        titleText.draw(at: CGPoint(x: margin + 5, y: 25), withAttributes: titleAttributes)
        
        let idText = "#\(String(invoice.id.uuidString.prefix(8)).uppercased())"
        let idAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 20, isBold: true),
            .foregroundColor: style.accentColor
        ]
        
        let idSize = idText.size(withAttributes: idAttributes)
        let badgeRect = CGRect(
            x: pageRect.width - margin - idSize.width - 25,
            y: 30,
            width: idSize.width + 16,
            height: 24
        )
        
        let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: 12)
        UIColor.white.setFill()
        badgePath.fill()
        
        idText.draw(at: CGPoint(x: badgeRect.midX - idSize.width / 2, y: badgeRect.midY - idSize.height / 2), withAttributes: idAttributes)
        
        return 115
    }
    
    private func drawBoxedHeader(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice, style: InvoiceTemplateStyle) -> CGFloat {
        let y = currentY
        
        let titleBoxRect = CGRect(x: margin, y: y, width: pageRect.width - 2 * margin, height: 80)
        
        let boxPath = UIBezierPath(roundedRect: titleBoxRect, cornerRadius: 6)
        style.secondaryColor.setFill()
        boxPath.fill()
        
        style.accentColor.setStroke()
        boxPath.lineWidth = 2
        boxPath.stroke()
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 24, isBold: true),
            .foregroundColor: style.accentColor
        ]
        
        let titleText = (invoice.invoiceTitle ?? "INVOICE").uppercased()
        let titleSize = titleText.size(withAttributes: titleAttributes)
        
        titleText.draw(at: CGPoint(
            x: titleBoxRect.midX - titleSize.width / 2,
            y: titleBoxRect.midY - titleSize.height / 2 - 4
        ), withAttributes: titleAttributes)
        
        let idText = "#\(String(invoice.id.uuidString.prefix(8)).uppercased())"
        let idAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 22),
            .foregroundColor: UIColor.secondaryText
        ]
        let idSize = idText.size(withAttributes: idAttributes)
        
        idText.draw(at: CGPoint(
            x: titleBoxRect.midX - idSize.width / 2,
            y: titleBoxRect.midY + 8
        ), withAttributes: idAttributes)
        
        return y + 75
    }
    
    private func drawCompanyInfo(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice, style: InvoiceTemplateStyle) -> CGFloat {
        var y = currentY
        let halfWidth = (pageRect.width - 2 * margin) / 2
        
        // --- Добавляем расчет ширины для левой колонки (Company Info) ---
        let leftColumnWidth = halfWidth - margin / 2 // Ширина левой колонки с небольшим запасом
        // -----------------------------------------------------------------

        let senderHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 22, isBold: true),
            .foregroundColor: style.accentColor,
            // Обязательно добавляем стиль параграфа для переноса
            .paragraphStyle: {
                let p = NSMutableParagraphStyle()
                p.lineBreakMode = .byWordWrapping
                return p
            }()
        ]
        let senderDetailAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 18),
            .foregroundColor: UIColor.primaryText,
            // Обязательно добавляем стиль параграфа для переноса
            .paragraphStyle: {
                let p = NSMutableParagraphStyle()
                p.lineBreakMode = .byWordWrapping
                return p
            }()
        ]
        
        "FROM:".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: style.getFont(size: 18), .foregroundColor: UIColor.secondaryText])
        y += 26
        
        let senderCompany = invoice.senderCompany ?? CompanyInfo.load()
        
        // --- Рисуем Имя Компании (с переносом) ---
        let companyNameRect = CGRect(x: margin, y: y, width: leftColumnWidth, height: 1000)
        let companyName = senderCompany?.name ?? ""
        let companyNameSize = companyName.boundingRect(with: companyNameRect.size, options: .usesLineFragmentOrigin, attributes: senderHeaderAttributes, context: nil)
        companyName.draw(in: companyNameRect, withAttributes: senderHeaderAttributes)
        y += max(26, companyNameSize.height) + 4 // Сдвиг на рассчитанную высоту + небольшой отступ
        // -----------------------------------------
        
        // --- Рисуем Улицу (с переносом) ---
        let streetRect = CGRect(x: margin, y: y, width: leftColumnWidth, height: 1000)
        let street = senderCompany?.street ?? ""
        let streetSize = street.boundingRect(with: streetRect.size, options: .usesLineFragmentOrigin, attributes: senderDetailAttributes, context: nil)
        street.draw(in: streetRect, withAttributes: senderDetailAttributes)
        y += max(23, streetSize.height) + 2
        // ----------------------------------
        
        // --- Рисуем Город/Индекс (с переносом) ---
        let cityZipRect = CGRect(x: margin, y: y, width: leftColumnWidth, height: 1000)
        let cityZip = senderCompany?.cityStateZip ?? ""
        let cityZipSize = cityZip.boundingRect(with: cityZipRect.size, options: .usesLineFragmentOrigin, attributes: senderDetailAttributes, context: nil)
        cityZip.draw(in: cityZipRect, withAttributes: senderDetailAttributes)
        y += max(23, cityZipSize.height) + 2
        // -----------------------------------------
        
        // --- Рисуем Email (с переносом) ---
        let emailRect = CGRect(x: margin, y: y, width: leftColumnWidth, height: 1000)
        let email = senderCompany?.email ?? ""
        let emailSize = email.boundingRect(with: emailRect.size, options: .usesLineFragmentOrigin, attributes: senderDetailAttributes, context: nil)
        email.draw(in: emailRect, withAttributes: senderDetailAttributes)
        y += emailSize.height
        // ----------------------------------
        
        let leftColumnMaxY = y + 15
        
        // --- Код для правой колонки (Invoice Details) остается без изменений ---
        let dateX = pageRect.width - margin - halfWidth + 40
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let dateLabelAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 18, isBold: true),
            .foregroundColor: UIColor.primaryText
        ]
        
        let dateValueAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 18),
            .foregroundColor: UIColor.primaryText,
            .paragraphStyle: {
                let p = NSMutableParagraphStyle()
                p.alignment = .right
                return p
            }()
        ]
        
        var rightY = currentY + 26
        
        let dateLabelWidth: CGFloat = halfWidth - 50 // Ширина, выделенная для подписи (например, "Invoice Date:")
        let valueWidth: CGFloat = 140 // **Увеличили ширину колонки значений (было 110)**
        let valueXPadding: CGFloat = 10 // **Добавили отступ между подписью и значением**

        let info: [(String, String?)] = [
            ("Invoice Date:", isEstimate ? nil : dateFormatter.string(from: invoice.invoiceDate)),
            ("Due Date:", isEstimate ? nil : dateFormatter.string(from: invoice.dueDate)),
            ("Status:", invoice.status.rawValue),
            ("Currency:", invoice.currency.code)
        ]
        
        for item in info {
            guard let detail = item.1 else { continue }
            
            item.0.draw(at: CGPoint(x: dateX, y: rightY), withAttributes: dateLabelAttributes)
            
            // Рассчитываем X-координату для значения с учетом отступа:
            // dateX + (dateLabelWidth - valueWidth) + 5 (старый отступ) + valueXPadding (новый отступ)
            let detailRectX = dateX + dateLabelWidth - valueWidth + 5 + valueXPadding
            
            let detailRect = CGRect(x: detailRectX, y: rightY, width: valueWidth, height: 25)
            
            // Рисуем значение (дату/статус)
            detail.draw(in: detailRect, withAttributes: dateValueAttributes)
            
            rightY += 26
        }
        // --------------------------------------------------------------------
        
        return max(leftColumnMaxY, rightY)
    }
    
    private func drawClientInfo(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice, style: InvoiceTemplateStyle) -> CGFloat {
        var y = currentY
        
        // --- Добавляем расчет ширины для клиентской информации ---
        let clientInfoWidth = pageRect.width / 2 - margin / 2 // Используем примерно половину ширины, как и для компании
        // --------------------------------------------------------

        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 18, isBold: true),
            .foregroundColor: style.accentColor
        ]
        "BILL TO:".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttributes)
        y += 26
        
        guard let client = invoice.client, let clientName = client.clientName, !clientName.isEmpty else {
            "N/A".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: style.getFont(size: 18, isBold: true), .foregroundColor: UIColor.secondaryText])
            return y + 20
        }
        
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 20, isBold: true),
            .foregroundColor: UIColor.primaryText,
            // Обязательно добавляем стиль параграфа для переноса
            .paragraphStyle: {
                let p = NSMutableParagraphStyle()
                p.lineBreakMode = .byWordWrapping
                return p
            }()
        ]
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 18),
            .foregroundColor: UIColor.secondaryText,
            // Обязательно добавляем стиль параграфа для переноса
            .paragraphStyle: {
                let p = NSMutableParagraphStyle()
                p.lineBreakMode = .byWordWrapping
                return p
            }()
        ]
        
        // --- Рисуем Имя Клиента (с переносом) ---
        let clientNameRect = CGRect(x: margin, y: y, width: clientInfoWidth, height: 1000)
        let clientNameSize = clientName.boundingRect(with: clientNameRect.size, options: .usesLineFragmentOrigin, attributes: nameAttributes, context: nil)
        clientName.draw(in: clientNameRect, withAttributes: nameAttributes)
        y += max(26, clientNameSize.height) + 4
        // ---------------------------------------
        
        // --- Рисуем Адрес (с переносом) ---
        if let address = client.address, !address.isEmpty {
            let addressRect = CGRect(x: margin, y: y, width: clientInfoWidth, height: 1000)
            let addressSize = address.boundingRect(with: addressRect.size, options: .usesLineFragmentOrigin, attributes: detailAttributes, context: nil)
            address.draw(in: addressRect, withAttributes: detailAttributes)
            y += max(23, addressSize.height) + 2
        }
        // ----------------------------------
        
        // --- Рисуем Email (с переносом) ---
        if let email = client.email, !email.isEmpty {
            let emailRect = CGRect(x: margin, y: y, width: clientInfoWidth, height: 1000)
            let emailSize = email.boundingRect(with: emailRect.size, options: .usesLineFragmentOrigin, attributes: detailAttributes, context: nil)
            email.draw(in: emailRect, withAttributes: detailAttributes)
            y += max(23, emailSize.height) + 2
        }
        // ----------------------------------
        
        // --- Рисуем Телефон (с переносом) ---
        if let phone = client.phoneNumber, !phone.isEmpty {
            let phoneRect = CGRect(x: margin, y: y, width: clientInfoWidth, height: 1000)
            let phoneSize = phone.boundingRect(with: phoneRect.size, options: .usesLineFragmentOrigin, attributes: detailAttributes, context: nil)
            phone.draw(in: phoneRect, withAttributes: detailAttributes)
            y += max(23, phoneSize.height) + 2
        }
        // ------------------------------------
        
        if style == .classic || style == .minimal || style == .tealAccent {
            let line = UIBezierPath()
            let lineY = y + 20
            line.move(to: CGPoint(x: margin, y: lineY))
            line.addLine(to: CGPoint(x: pageRect.width - margin, y: lineY))
            (style == .classic ? UIColor.systemGray : style.accentColor.withAlphaComponent(0.5)).setStroke()
            line.lineWidth = style == .classic ? 0.5 : 1
            line.stroke()
            return lineY + 18
        }
        
        return y + 15
    }
    
    private func drawItemsTable(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice, style: InvoiceTemplateStyle) -> CGFloat {
        var y = currentY
        let tableWidth = pageRect.width - 2 * margin
        let columnWidths: [CGFloat] = [
            tableWidth * 0.40,
            tableWidth * 0.15,
            tableWidth * 0.20,
            tableWidth * 0.25
        ]
        let headers = ["DESCRIPTION", "QTY", "UNIT PRICE", "AMOUNT"]
        let rowHeight: CGFloat = 25
        let textInset: CGFloat = 5
        let isBoxed = style == .boxed
        
        var currentX: CGFloat = margin
        for (index, header) in headers.enumerated() {
            let rect = CGRect(x: currentX, y: y, width: columnWidths[index], height: rowHeight)
            
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: style.getFont(size: 16, isBold: true),
                .foregroundColor: style == .vibrant ? UIColor.primaryText : UIColor.white,
                .paragraphStyle: {
                    let p = NSMutableParagraphStyle()
                    p.alignment = index < 2 ? .left : .right
                    return p
                }()
            ]
            
            if style == .vibrant {
                style.secondaryColor.setFill()
                UIRectFill(rect)
            } else {
                style.accentColor.setFill()
                UIRectFill(rect)
            }
            
            header.uppercased().draw(in: rect.insetBy(dx: textInset, dy: 0), withAttributes: headerAttributes)
            currentX += columnWidths[index]
        }
        y += rowHeight
        
        let itemDetailAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 16),
            .foregroundColor: UIColor.primaryText,
            .paragraphStyle: {
                let p = NSMutableParagraphStyle()
                p.lineBreakMode = .byWordWrapping
                return p
            }()
        ]
        let itemValueAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 16, isBold: true),
            .foregroundColor: UIColor.primaryText,
            .paragraphStyle: {
                let p = NSMutableParagraphStyle()
                p.alignment = .right
                return p
            }()
        ]
        
        let currencyFormatter = NumberFormatter.currencyFormatter(for: invoice.currency)
        let context = UIGraphicsGetCurrentContext()
        
        for (index, item) in (invoice.items).enumerated() {
            let isStripe = index % 2 != 0
            currentX = margin
            
            let descText = item.name ?? item.description
            let descriptionRect = CGRect(x: currentX + textInset, y: y + textInset, width: columnWidths[0] - 2 * textInset, height: 1000)
            let descriptionSize = descText.boundingRect(
                with: CGSize(width: columnWidths[0] - 2 * textInset, height: 1000),
                options: .usesLineFragmentOrigin,
                attributes: itemDetailAttributes,
                context: nil
            )
            let actualRowHeight = max(rowHeight, descriptionSize.height + 2 * textInset) + 10
            let rowRect = CGRect(x: margin, y: y, width: tableWidth, height: actualRowHeight)
            
            if isStripe {
                style.tableStripeColor.setFill()
                UIRectFill(rowRect)
            } else if isBoxed {
                UIColor.white.setFill()
                UIRectFill(rowRect)
            }
            
            descText.draw(in: descriptionRect, withAttributes: itemDetailAttributes)
            currentX += columnWidths[0]
            
            let qtyRect = CGRect(x: currentX, y: y, width: columnWidths[1], height: actualRowHeight).insetBy(dx: textInset, dy: 0)
            
            let qtyAttributes: [NSAttributedString.Key: Any] = [
                .font: style.getFont(size: 16),
                .foregroundColor: UIColor.primaryText,
                .paragraphStyle: {
                    let p = NSMutableParagraphStyle()
                    p.alignment = .center
                    return p
                }()
            ]
            
            String(format: "%.0f %@", item.quantity, item.unitType.rawValue).draw(in: qtyRect, withAttributes: qtyAttributes)
            currentX += columnWidths[1]
            
            let priceString = currencyFormatter.string(from: NSNumber(value: item.unitPrice)) ?? ""
            let priceRect = CGRect(x: currentX, y: y, width: columnWidths[2], height: actualRowHeight).insetBy(dx: textInset, dy: 0)
            priceString.draw(in: priceRect, withAttributes: itemValueAttributes)
            currentX += columnWidths[2]
            
            let total = item.lineTotal
            let totalString = currencyFormatter.string(from: NSNumber(value: total)) ?? ""
            let totalRect = CGRect(x: currentX, y: y, width: columnWidths[3], height: actualRowHeight).insetBy(dx: textInset, dy: 0)
            totalString.draw(in: totalRect, withAttributes: itemValueAttributes)
            currentX += columnWidths[3]
            
            if isBoxed {
                let line = UIBezierPath()
                line.move(to: CGPoint(x: margin, y: y + actualRowHeight))
                line.addLine(to: CGPoint(x: pageRect.width - margin, y: y + actualRowHeight))
                UIColor.systemGray.withAlphaComponent(0.3).setStroke()
                line.lineWidth = 0.5
                line.stroke()
            }
            
            y += actualRowHeight
            
            if y + actualRowHeight > pageRect.height - 100 {
                var box = pageRect
                context?.beginPage(mediaBox: &box)
                y = margin
            }
        }
        
        return y + 15
    }
    
    private func drawSummary(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice, style: InvoiceTemplateStyle) -> CGFloat {
        var y = currentY
        let summaryWidth = (pageRect.width - 2 * margin) * 0.40
        let summaryX = pageRect.width - margin - summaryWidth
        let lineItemHeight: CGFloat = 28
        let currencyFormatter = NumberFormatter.currencyFormatter(for: invoice.currency)
        
        let subtotal = invoice.subtotal
        let taxAmount = invoice.taxTotal
        
        let discountLabel: String
        let discountAmount: Double
        
        switch invoice.discountType {
        case .percentage:
            let rateString = String(format: "%.0f%%", invoice.discount)
            discountLabel = "Discount (\(rateString)):"
            discountAmount = invoice.discountValue
            
        case .fixedAmount:
            discountLabel = "Discount (\(invoice.currencySymbol)):"
            discountAmount = invoice.discount
        }
        
        let summaryData: [(String, Double)] = [
            ("Subtotal:", subtotal),
            ("Tax (\(String(format: "%.0f%%", invoice.taxRate))):", taxAmount),
            (discountLabel, -discountAmount),
            ("Total:", invoice.grandTotal)
        ]
        
        for data in summaryData {
            let isTotal = data.0.contains("Total:")
            let labelColor = isTotal ? style.accentColor : UIColor.primaryText
            
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: style.getFont(size: 18, isBold: isTotal),
                .foregroundColor: labelColor,
                .paragraphStyle: {
                    let p = NSMutableParagraphStyle()
                    p.alignment = .left
                    return p
                }()
            ]
            
            let valueAttributes: [NSAttributedString.Key: Any] = [
                .font: style.getFont(size: isTotal ? 20 : 18, isBold: isTotal),
                .foregroundColor: labelColor,
                .paragraphStyle: {
                    let p = NSMutableParagraphStyle()
                    p.alignment = .right
                    return p
                }()
            ]
            
            let valueString = currencyFormatter.string(from: NSNumber(value: data.1)) ?? "N/A"
            
            let labelRect = CGRect(x: summaryX, y: y, width: summaryWidth * 0.60, height: lineItemHeight)
            let valueRect = CGRect(x: summaryX + summaryWidth * 0.60, y: y, width: summaryWidth * 0.40, height: lineItemHeight)
            
            if isTotal {
                let totalRect = CGRect(x: summaryX, y: y - 3, width: summaryWidth, height: lineItemHeight + 6)
                style.secondaryColor.setFill()
                UIRectFill(totalRect)
            }
            
            data.0.draw(in: labelRect, withAttributes: labelAttributes)
            valueString.draw(in: valueRect, withAttributes: valueAttributes)
            
            y += lineItemHeight
        }
        
        return y + 25
    }
    
    private func drawFooter(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, style: InvoiceTemplateStyle, isEstimate: Bool) -> CGFloat {
        let text = isEstimate ? "Thank you for considering our estimate!" : "Thank you for your business!"
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 20, isBold: true),
            .foregroundColor: style.accentColor,
            .paragraphStyle: {
                let p = NSMutableParagraphStyle()
                p.alignment = .center
                return p
            }()
        ]
        
        let textRect = CGRect(x: margin, y: currentY, width: pageRect.width - 2 * margin, height: 30)
        
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin, y: currentY - 4))
        line.addLine(to: CGPoint(x: pageRect.width - margin, y: currentY - 4))
        UIColor.systemGray.withAlphaComponent(0.5).setStroke()
        line.lineWidth = 0.5
        line.stroke()
        
        text.draw(in: textRect, withAttributes: attributes)
        
        return currentY + 25
    }
    
    private func convertButtonTapped() {
        invoice?.status = .readyToSend

        guard let invoice else { return }
        
        try? invoiceService?.save(invoice: invoice)
        try? estimateService?.deleteEstimate(id: invoice.id)
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func editTapped() {
        guard let invoice = invoice else { return }

        let editInvoiceViewController = isEstimate ? EditEstimateViewController(invoice: invoice) : EditInvoiceViewController(invoice: invoice)
        editInvoiceViewController.popEditInvoiceViewControllerHandler = { [weak self] updatedInvoice in
            self?.invoice = updatedInvoice
            self?.generateAndLoadPDF()
            self?.title = self?.invoice?.invoiceTitle ?? "Invoice Preview"
        }
        navigationController?.pushViewController(editInvoiceViewController, animated: true)
    }
    
    private func sendButtonTapped() {
        guard let invoice = invoice else { return }
        let pdfData = generatePDF(for: invoice, style: currentStyle)
        
        let titlePrefix = isEstimate ? "Estimate" : "Invoice" // ⭐ ОБНОВЛЕНИЕ
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(titlePrefix)-\(invoice.invoiceTitle ?? "Document").pdf")
        try? pdfData.write(to: tempURL)
        
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
    }
}

extension InvoiceDetailPDFViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

extension InvoiceDetailPDFViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return InvoiceTemplateStyle.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TemplatePreviewCell.reuseIdentifier, for: indexPath) as? TemplatePreviewCell else {
            return UICollectionViewCell()
        }
        
        let style = InvoiceTemplateStyle.allCases[indexPath.item]
        let isSelected = style == currentStyle
        
        guard let invoice = invoice else {
            return cell
        }
        
        let pdfData = generatePDF(for: invoice, style: style)
        cell.configure(with: style, pdfData: pdfData, isSelected: isSelected)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentStyle = InvoiceTemplateStyle.allCases[indexPath.item]
    }
}

extension NumberFormatter {
    static func currencyFormatter(for currency: Currency) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        formatter.currencySymbol = currency.symbol
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
    
    static func percentFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }
}
