import UIKit
import SnapKit
import PDFKit
import MessageUI

// MARK: - Template Definition
enum InvoiceTemplateStyle: String, CaseIterable {
    case modern = "Modern (Blue)"
    case classic = "Classic (B&W)"
    case minimal = "Minimal (Gray)"
    case vibrant = "Vibrant (Red)"
    case tealAccent = "Teal Accent"
    case goldTheme = "Gold Theme"
    case boxed = "Boxed (Green)"

    var accentColor: UIColor {
        switch self {
        case .modern: return UIColor.systemBlue // Базовый цвет
        case .classic: return UIColor.black // Черный/серый
        case .minimal: return UIColor.systemGray // Светло-серый
        case .vibrant: return UIColor.systemRed // Красный
        case .tealAccent: return UIColor(red: 0.1, green: 0.6, blue: 0.6, alpha: 1.0) // Бирюзовый
        case .goldTheme: return UIColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1.0) // Золотой/Коричневый
        case .boxed: return UIColor.systemGreen // Зеленый
        }
    }
    
    // Вспомогательное свойство для типа шрифта
    var isSerifFont: Bool {
        switch self {
        case .classic, .goldTheme: return true
        default: return false
        }
    }
    
    // Вспомогательное свойство для цвета фона таблицы
    var tableStripeColor: UIColor {
        switch self {
        case .minimal: return UIColor.systemGray.withAlphaComponent(0.05)
        case .tealAccent: return accentColor.withAlphaComponent(0.08)
        case .boxed: return accentColor.withAlphaComponent(0.1)
        case .goldTheme: return accentColor.withAlphaComponent(0.1)
        default: return UIColor.surface
        }
    }
    
    // Вспомогательная функция для получения шрифта
    func getFont(size: CGFloat, isBold: Bool = false) -> UIFont {
        if isSerifFont {
            if isBold {
                return UIFont(name: "TimesNewRomanPS-BoldMT", size: size) ?? UIFont.boldSystemFont(ofSize: size)
            } else {
                return UIFont(name: "TimesNewRomanPSMT", size: size) ?? UIFont.systemFont(ofSize: size)
            }
        } else {
            return isBold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
        }
    }
}

class InvoiceDetailPDFViewController: UIViewController {

    // MARK: - Properties
    
    var isEstimate: Bool = false
    var invoice: Invoice?
    private let pdfView = PDFView()
    
    // ⭐ НОВОЕ: Текущий выбранный шаблон (по умолчанию Modern)
    private var currentStyle: InvoiceTemplateStyle = .modern {
        didSet {
            generateAndLoadPDF()
            // Обновляем CollectionView, чтобы показать выделение
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
    
    // MARK: - UI Elements
    
    // ⭐ НОВЫЙ UI ЭЛЕМЕНТ: Коллекция для выбора шаблона
    private lazy var styleCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 120) // Размер превью
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TemplatePreviewCell.self, forCellWithReuseIdentifier: TemplatePreviewCell.reuseIdentifier)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    private lazy var convertButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Convert Estimate to Invoice"
        config.image = UIImage(systemName: "repeat.circle.fill")
        config.imagePadding = 10
        
        config.baseBackgroundColor = .secondary
        config.baseForegroundColor = .white
        config.buttonSize = .large
        
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.convertButtonTapped()
        })
        button.layer.cornerRadius = 14
        button.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 4
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        return button
    }()
    
    private lazy var sendButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = isEstimate ? "Send Estimate (PDF)" : "Send Invoice (PDF)"
        config.image = UIImage(systemName: "paperplane.fill")
        config.imagePadding = 10
        
        config.baseBackgroundColor = .primary
        config.baseForegroundColor = .white
        config.buttonSize = .large
        
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.sendButtonTapped()
        })
        button.layer.cornerRadius = 14
        button.layer.shadowColor = UIColor.primary.cgColor
        button.layer.shadowOpacity = 0.4
        button.layer.shadowRadius = 8
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        return button
    }()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard invoice != nil else {
            print("Error: Invoice model not set.")
            dismiss(animated: true)
            return
        }
        
        setupUI()
        generateAndLoadPDF()
        
        // Выбираем первый элемент по умолчанию
        DispatchQueue.main.async {
            self.styleCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: [])
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .background
        
        title = isEstimate ? "Estimate Preview" : (invoice?.invoiceTitle ?? "Invoice Preview")
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editTapped))
        
        view.addSubview(pdfView)
        view.addSubview(sendButton)
        view.addSubview(styleCollectionView) // ⭐ ДОБАВЛЯЕМ COLLECTION VIEW
        
        var bottomOffset: CGFloat = 10
        var topOfButtonsConstraint: ConstraintRelatableTarget = styleCollectionView.snp.top // Якорь PDF теперь CollectionView
        
        // ⭐ УСЛОВИЕ: Добавляем кнопку Convert, если это Estimate
        if isEstimate {
            view.addSubview(convertButton)
            
            // 1. Располагаем кнопку Convert над Send Button
            convertButton.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(20)
                make.bottom.equalTo(sendButton.snp.top).offset(-10)
                make.height.equalTo(56)
            }
            // Смещаем якорь для CollectionView
            topOfButtonsConstraint = convertButton.snp.top
        } else {
            topOfButtonsConstraint = sendButton.snp.top
        }
        
        // 1. Располагаем Collection View над кнопками
        styleCollectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            // Привязываем к верхней точке кнопок с отступом
            make.bottom.equalTo(topOfButtonsConstraint).offset(-10)
            make.height.equalTo(130)
        }
        
        // 2. Располагаем Send Button внизу
        sendButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(bottomOffset)
            make.height.equalTo(56)
        }
        
        // 3. Располагаем PDFView
        pdfView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            // Привязываем нижний край к Collection View
            make.bottom.equalTo(styleCollectionView.snp.top).offset(-10)
        }
        
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        pdfView.displayMode = .singlePage
        pdfView.backgroundColor = .background
        pdfView.layer.cornerRadius = 8
        pdfView.clipsToBounds = true
    }
    
    // MARK: - PDF Generation and Loading
    
    private func generateAndLoadPDF() {
        guard let invoice = invoice else { return }
        // ⭐ ПЕРЕДАЕМ ТЕКУЩИЙ СТИЛЬ
        let pdfData = generatePDF(for: invoice, style: currentStyle)
        
        if let document = PDFDocument(data: pdfData) {
            pdfView.document = document
        } else {
            let alert = UIAlertController(title: "Error", message: "Could not generate PDF document.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    // ⭐ ОБНОВЛЕННЫЙ generatePDF: теперь принимает Style
    private func generatePDF(for invoice: Invoice, style: InvoiceTemplateStyle) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            
            let margin: CGFloat = 40
            var currentY: CGFloat = margin
            
            // --- 1. Header (Title, ID) ---
            currentY = drawHeader(pageRect: pageRect, currentY: currentY, margin: margin, invoice: invoice, style: style)
            
            // --- 2. Sender Info & Dates/Status ---
            currentY = drawCompanyInfo(pageRect: pageRect, currentY: currentY + 10, margin: margin, invoice: invoice, style: style)
            
            // --- 3. Client Info (BILL TO) ---
            currentY = drawClientInfo(pageRect: pageRect, currentY: currentY + 30, margin: margin, invoice: invoice, style: style)
            
            // --- 4. Items Table ---
            currentY = drawItemsTable(pageRect: pageRect, currentY: currentY + 30, margin: margin, invoice: invoice, style: style)
            
            // --- 5. Summary / Totals ---
            currentY = drawSummary(pageRect: pageRect, currentY: currentY + 30, margin: margin, invoice: invoice, style: style)
            
            // --- 6. Footer (Payment Notes / Status) ---
            _ = drawFooter(pageRect: pageRect, currentY: 800, margin: margin, style: style, isEstimate: isEstimate) // Фиксированное место внизу
        }
        
        return pdfData
    }
    
    // MARK: - PDF Drawing Helper Functions (ОБНОВЛЕНО СО СТИЛЯМИ)
    
    private func drawHeader(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice, style: InvoiceTemplateStyle) -> CGFloat {
        var y = currentY
        let textRect = CGRect(x: margin, y: y, width: pageRect.width - 2 * margin, height: 50)
        
        // Title (Left)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 32, isBold: true),
            .foregroundColor: style.accentColor
        ]
        let titleText = (invoice.invoiceTitle ?? "INVOICE").uppercased()
        titleText.draw(in: textRect, withAttributes: titleAttributes)
        
        // ID (Right)
        let idText = "INVOICE ID: \(invoice.id.uuidString.prefix(8).uppercased())"
        
        let idAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 12, isBold: true),
            .foregroundColor: UIColor.secondaryText
        ]
        
        let idSize = idText.size(withAttributes: idAttributes)
        let idRect = CGRect(x: pageRect.width - margin - idSize.width, y: y + 5, width: idSize.width, height: idSize.height)
        idText.draw(in: idRect, withAttributes: idAttributes)
        
        y += 50
        
        // Draw a separator line
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin, y: y + 5))
        line.addLine(to: CGPoint(x: pageRect.width - margin, y: y + 5))
        
        // Разные стили линий
        if style == .classic || style == .minimal {
            UIColor.systemGray.setStroke()
            line.lineWidth = 1
        } else {
            style.accentColor.setStroke()
            line.lineWidth = 3
        }
        line.stroke()
        
        return y + 15
    }
    
    private func drawCompanyInfo(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice, style: InvoiceTemplateStyle) -> CGFloat {
        var y = currentY
        let halfWidth = (pageRect.width - 2 * margin) / 2
        
        // --- LEFT SIDE: SENDER (Mock Info) ---
        let senderHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 16, isBold: true),
            .foregroundColor: style.accentColor
        ]
        let senderDetailAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 12),
            .foregroundColor: UIColor.primaryText
        ]
        
        "FROM:".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: style.getFont(size: 12), .foregroundColor: UIColor.secondaryText])
        y += 20
        
        let senderCompany = invoice.senderCompany ?? CompanyInfo.load()
        (senderCompany?.name ?? "").draw(at: CGPoint(x: margin, y: y), withAttributes: senderHeaderAttributes)
        y += 20
        (senderCompany?.street ?? "").draw(at: CGPoint(x: margin, y: y), withAttributes: senderDetailAttributes)
        y += 15
        ((senderCompany?.cityStateZip ?? "")).draw(at: CGPoint(x: margin, y: y), withAttributes: senderDetailAttributes)
        y += 15
        (senderCompany?.email ?? "").draw(at: CGPoint(x: margin, y: y), withAttributes: senderDetailAttributes)
        
        let leftColumnMaxY = y + 10
        
        // --- RIGHT SIDE: Dates, Status, Currency ---
        let dateX = pageRect.width - margin - halfWidth // Сдвигаем направо
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let dateLabelAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 12, isBold: true),
            .foregroundColor: UIColor.primaryText
        ]
        
        var rightY = currentY + 20
        
        let dateLabelWidth = halfWidth - 10
        let alignment: NSTextAlignment = style == .boxed ? .left : .right
        
        let info = [
            ("Invoice Date:", isEstimate ? nil : dateFormatter.string(from: invoice.invoiceDate)),
            ("Due Date:", isEstimate ? nil : dateFormatter.string(from: invoice.dueDate)),
            ("Status:", invoice.status.rawValue),
            ("Currency:", "\(invoice.currency.code) (\(invoice.currencySymbol))")
        ]
        
        for item in info {
            guard let detail = item.1 else { continue }
            
            // Лейбл (слева)
            let labelSize = item.0.size(withAttributes: dateLabelAttributes)
            let labelX = dateX + (alignment == .right ? dateLabelWidth - labelSize.width : 0) // Если right, начинаем правее
            
            if style != .boxed {
                // Style: Classic, Modern - выравнивание по правому краю
                item.0.draw(at: CGPoint(x: dateX + dateLabelWidth - labelSize.width - 70, y: rightY), withAttributes: dateLabelAttributes)
                
                // Значение (справа)
                let detailAttributes: [NSAttributedString.Key: Any] = [
                    .font: style.getFont(size: 12),
                    .foregroundColor: UIColor.primaryText
                ]
                let detailSize = detail.size(withAttributes: detailAttributes)
                let detailX = dateX + dateLabelWidth - detailSize.width
                detail.draw(at: CGPoint(x: detailX, y: rightY), withAttributes: detailAttributes)
                
            } else {
                // Style: Boxed - все в рамке
                let text = "\(item.0) \(detail)"
                let textRect = CGRect(x: dateX, y: rightY, width: dateLabelWidth, height: 20)
                
                let box = UIBezierPath(rect: textRect.insetBy(dx: 0, dy: -2))
                style.accentColor.withAlphaComponent(0.1).setFill()
                box.fill()
                
                text.draw(at: CGPoint(x: dateX + 5, y: rightY), withAttributes: dateLabelAttributes)
            }
            
            rightY += 20
        }
        
        return max(leftColumnMaxY, rightY + 10)
    }

    private func drawClientInfo(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice, style: InvoiceTemplateStyle) -> CGFloat {
        var y = currentY
        
        // Заголовок "BILL TO"
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 12, isBold: true),
            .foregroundColor: style.accentColor
        ]
        "BILL TO:".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttributes)
        y += 20
        
        guard let client = invoice.client, let clientName = client.clientName, !clientName.isEmpty else {
            "N/A (Client not specified)".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: style.getFont(size: 12, isBold: true), .foregroundColor: UIColor.secondaryText])
            return y + 30
        }
        
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 14, isBold: true),
            .foregroundColor: UIColor.primaryText
        ]
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 12),
            .foregroundColor: UIColor.secondaryText
        ]
        
        // Client Name
        clientName.draw(at: CGPoint(x: margin, y: y), withAttributes: nameAttributes)
        y += 20
        
        // Address
        if let address = client.address, !address.isEmpty {
            address.draw(at: CGPoint(x: margin, y: y), withAttributes: detailAttributes)
            y += 35 // Multiline space
        }
        
        // Email
        if let email = client.email, !email.isEmpty {
            email.draw(at: CGPoint(x: margin, y: y), withAttributes: detailAttributes)
            y += 15
        }
        
        // Phone Number
        if let phone = client.phoneNumber, !phone.isEmpty {
            phone.draw(at: CGPoint(x: margin, y: y), withAttributes: detailAttributes)
            y += 15
        }

        // Client Type
        if client.clientType != .newClient {
            let typeText = "Type: \(client.clientType.localized)"
            typeText.draw(at: CGPoint(x: margin, y: y), withAttributes: detailAttributes)
            y += 15
        }
        
        // Разделяющая линия
        if style == .minimal {
            let line = UIBezierPath()
            line.move(to: CGPoint(x: margin, y: y + 5))
            line.addLine(to: CGPoint(x: pageRect.width - margin, y: y + 5))
            UIColor.systemGray.setStroke()
            line.lineWidth = 0.5
            line.stroke()
        }
        
        return y + 10
    }
    
    private func drawItemsTable(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice, style: InvoiceTemplateStyle) -> CGFloat {
        var y = currentY
        let pageWidth = pageRect.width - 2 * margin
        let rowHeight: CGFloat = 35
        
        let currencySymbol = invoice.currencySymbol
        
        let colWidths: [CGFloat] = [0.4, 0.1, 0.15, 0.15, 0.2]
        let headers = ["Item / Description", "Qty", "Unit Price", "Discount", "Line Total"]
        
        var currentX: CGFloat = margin
        var colStarts: [CGFloat] = []
        
        for widthRatio in colWidths {
            colStarts.append(currentX)
            currentX += pageWidth * widthRatio
        }
        
        // --- 1. Draw Table Header ---
        let headerRect = CGRect(x: margin, y: y, width: pageWidth, height: rowHeight)
        
        let headerFillColor = (style == .boxed || style == .vibrant) ? style.accentColor : UIColor.systemGray // Базовый цвет для заливки заголовка
        headerFillColor.setFill()
        UIRectFill(headerRect)
        
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 10, isBold: true),
            // В Classic/Minimal/Modern можно использовать темный текст на светлом фоне
            .foregroundColor: (style == .classic || style == .minimal || style == .modern) ? UIColor.black : UIColor.white
        ]
        
        for (index, header) in headers.enumerated() {
            let colStart = colStarts[index]
            let colWidth = pageWidth * colWidths[index]
            
            // Выравнивание: Item/Description - по левому краю, остальные - по правому
            let textAlignment: NSTextAlignment = (index == 0) ? .left : .right
            let padding: CGFloat = 5
            
            let centeredX: CGFloat
            if textAlignment == .left {
                centeredX = colStart + padding
            } else {
                let size = header.size(withAttributes: headerAttributes)
                centeredX = colStart + colWidth - size.width - padding
            }
            
            header.draw(at: CGPoint(x: centeredX, y: y + 10), withAttributes: headerAttributes)
        }
        y += rowHeight
        
        // --- 2. Draw Items ---
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 10, isBold: true),
            .foregroundColor: UIColor.primaryText
        ]
        let descAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 8),
            .foregroundColor: UIColor.secondaryText
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 10),
            .foregroundColor: UIColor.primaryText
        ]
        
        for (index, item) in invoice.items.enumerated() {
            let rowRect = CGRect(x: margin, y: y, width: pageWidth, height: rowHeight)
            
            // Чередование фона строк
            if index % 2 != 0 {
                style.tableStripeColor.setFill()
                UIRectFill(rowRect)
            }
            
            let qtyUnit = item.unitType == .item ? "" : " \(item.unitType.localized.prefix(1))"
            let qty = String(format: "%.1f%@", item.quantity, qtyUnit)
            let unitPrice = "\(currencySymbol)\(String(format: "%.2f", item.unitPrice))"
            
            let discountValueString: String
            if item.discountType == .percentage {
                discountValueString = String(format: "%.0f%%", item.discountValue)
            } else {
                discountValueString = "\(currencySymbol)\(String(format: "%.2f", item.discountValue))"
            }
            
            let lineTotal = "\(currencySymbol)\(String(format: "%.2f", item.lineTotal))"
            
            let values = [
                (name: item.name ?? "Item", description: item.description),
                (qty, nil),
                (unitPrice, nil),
                (discountValueString, nil),
                (lineTotal, nil)
            ]
            
            for (colIndex, tuple) in values.enumerated() {
                let colStart = colStarts[colIndex]
                let colWidth = pageWidth * colWidths[colIndex]
                let padding: CGFloat = 5
                
                if colIndex == 0 {
                    // Name
                    tuple.0.draw(at: CGPoint(x: colStart + padding, y: y + 4), withAttributes: nameAttributes)
                    
                    // Description
                    if let desc = tuple.1, !desc.isEmpty {
                        let descRect = CGRect(x: colStart + padding, y: y + 18, width: colWidth - 2 * padding, height: 15)
                        desc.draw(in: descRect, withAttributes: descAttributes)
                    }
                    
                } else {
                    // Other columns: Right-aligned
                    let value = tuple.0
                    let size = value.size(withAttributes: valueAttributes)
                    let textX = colStart + colWidth - size.width - padding
                    
                    value.draw(at: CGPoint(x: textX, y: y + (rowHeight - size.height) / 2), withAttributes: valueAttributes)
                }
            }
            
            // Draw horizontal line separator
            let separator = UIBezierPath()
            separator.move(to: CGPoint(x: margin, y: y + rowHeight))
            separator.addLine(to: CGPoint(x: pageRect.width - margin, y: y + rowHeight))
            
            // Разные стили для разделителей
            if style == .minimal {
                UIColor.systemGray.withAlphaComponent(0.3).setStroke()
                separator.lineWidth = 0.5
            } else if style == .boxed {
                style.accentColor.setStroke()
                separator.lineWidth = 1
            } else {
                UIColor.border.setStroke()
                separator.lineWidth = 0.5
            }
            separator.stroke()
            
            y += rowHeight
        }
        
        return y
    }
    
    private func drawSummary(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice, style: InvoiceTemplateStyle) -> CGFloat {
        var y = currentY
        let summaryWidth: CGFloat = 180
        let summaryX = pageRect.width - margin - summaryWidth
        let currencySymbol = invoice.currencySymbol
        
        // --- Subtotal ---
        y = drawSummaryRow(y: y, x: summaryX, width: summaryWidth, label: "Subtotal:", value: invoice.subtotal, currencySymbol: currencySymbol, symbolType: .currency, isBold: false, style: style)
        
        // --- Tax ---
        let taxRateDisplay = String(format: "%.1f", invoice.taxRate * 100)
        y = drawSummaryRow(y: y, x: summaryX, width: summaryWidth, label: "Tax (\(taxRateDisplay)%):", value: invoice.taxTotal, currencySymbol: currencySymbol, symbolType: .currency, isBold: false, style: style)
        
        // --- Total Discount (на инвойс) ---
        if invoice.discountValue != 0 {
            let discountLabel = "Invoice Discount:"
            let discountAmount = abs(invoice.discountValue)
            let isPercentage = invoice.discountType == .percentage
            
            let valueToDisplay: Double
            let symbolType: SummarySymbolType
            
            if isPercentage {
                valueToDisplay = invoice.discount
                symbolType = .percent
            } else {
                valueToDisplay = discountAmount
                symbolType = .currency
            }
            
            y = drawSummaryRow(y: y, x: summaryX, width: summaryWidth,
                                label: discountLabel,
                                value: -discountAmount,
                                currencySymbol: currencySymbol,
                                symbolType: symbolType,
                                valueToDisplay: valueToDisplay,
                                isBold: false, style: style)
        }
        
        // Draw thick separator line
        let line = UIBezierPath()
        line.move(to: CGPoint(x: summaryX, y: y + 2))
        line.addLine(to: CGPoint(x: pageRect.width - margin, y: y + 2))
        style.accentColor.setStroke() // Толстая линия акцентного цвета
        line.lineWidth = 2
        line.stroke()
        
        y += 5
        
        // --- GRAND TOTAL ---
        y = drawSummaryRow(y: y, x: summaryX, width: summaryWidth, label: "GRAND TOTAL: ", value: invoice.grandTotal, currencySymbol: currencySymbol, symbolType: .currency, isBold: true, fontSize: 16, color: style.accentColor, style: style)
        
        return y
    }
    
    private func drawSummaryRow(y: CGFloat, x: CGFloat, width: CGFloat, label: String, value: Double, currencySymbol: String, symbolType: SummarySymbolType, valueToDisplay: Double? = nil, isBold: Bool, fontSize: CGFloat = 12, color: UIColor? = nil, style: InvoiceTemplateStyle) -> CGFloat {
        
        let displayValue = valueToDisplay ?? abs(value)

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: fontSize, isBold: isBold),
            .foregroundColor: color ?? UIColor.primaryText
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: fontSize, isBold: isBold),
            .foregroundColor: color ?? UIColor.primaryText
        ]
        
        // Draw label (Left side of summary box)
        label.draw(at: CGPoint(x: x, y: y), withAttributes: labelAttributes)
        
        let formattedValue: String
        switch symbolType {
        case .currency:
            let sign = (value < 0 && valueToDisplay == nil) ? "-" : "" // Если это скидка (value < 0), но не процент
            formattedValue = "\(sign)\(currencySymbol)\(String(format: "%.2f", abs(displayValue)))"
        case .percent:
            formattedValue = String(format: "%.0f%%", displayValue)
        }
        
        // Draw value (Right side of summary box)
        let size = formattedValue.size(withAttributes: valueAttributes)
        let valueX = x + width - size.width // Right alignment
        formattedValue.draw(at: CGPoint(x: valueX, y: y + (20 - size.height) / 2), withAttributes: valueAttributes)
        
        return y + 20
    }
    
    private func drawFooter(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, style: InvoiceTemplateStyle, isEstimate: Bool) -> CGFloat {
        let y = currentY
        
        let footerText = "Thank you for your business. Please remit payment by the due date. Contact us if you have any questions."
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        var attributes: [NSAttributedString.Key: Any] = [
            .font: style.getFont(size: 10),
            .foregroundColor: style.accentColor,
            .paragraphStyle: paragraphStyle
        ]
        
        let footerRect = CGRect(x: margin, y: y, width: pageRect.width - 2 * margin, height: 40)
        
        if !isEstimate {
            if style == .classic {
                attributes[.foregroundColor] = UIColor.black
            } else if style == .minimal {
                return y + 40
            }
            
            footerText.draw(in: footerRect, withAttributes: attributes)
        }
        
        return y + 40
    }

    // MARK: - Actions
    
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
        // ⭐ Генерируем PDF с текущим выбранным стилем
        let pdfData = generatePDF(for: invoice, style: currentStyle)
        
        let titlePrefix = isEstimate ? "Estimate" : "Invoice"
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

// MARK: - Collection View Delegate and Data Source

extension InvoiceDetailPDFViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return InvoiceTemplateStyle.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TemplatePreviewCell.reuseIdentifier, for: indexPath) as? TemplatePreviewCell else {
            return UICollectionViewCell()
        }
        
        let style = InvoiceTemplateStyle.allCases[indexPath.row]
        
        // Генерируем мини-PDF для превью
        let pdfData = generatePDF(for: invoice!, style: style)
        
        cell.configure(with: style, pdfData: pdfData, isSelected: style == currentStyle)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedStyle = InvoiceTemplateStyle.allCases[indexPath.row]
        currentStyle = selectedStyle
        
        // Коллекция перезагрузится через didSet currentStyle, но можем и здесь
        // styleCollectionView.reloadData()
    }
}


// MARK: - MessageUI Delegate (Для закрытия окна почты)

extension InvoiceDetailPDFViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
        
        if let error = error {
            print("Mail composition failed with error: \(error.localizedDescription)")
        }
    }
}

// Добавим вспомогательный метод для объединения атрибутов (если у вас нет)
extension Dictionary {
    func merged(with dictionary: [Key: Value]) -> [Key: Value] {
        return self.merging(dictionary) { (_, new) in new }
    }
}
