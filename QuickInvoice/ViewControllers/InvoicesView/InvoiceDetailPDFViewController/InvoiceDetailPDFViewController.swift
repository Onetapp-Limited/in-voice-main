import UIKit
import SnapKit
import PDFKit // Необходимо для отображения PDF
import MessageUI

class InvoiceDetailPDFViewController: UIViewController {

    // MARK: - Properties
    
    var invoice: Invoice! // Принимает модель инвойса
    private let pdfView = PDFView()
    
    // MARK: - UI Elements
    
    private lazy var sendButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Send Invoice (PDF)"
        config.image = UIImage(systemName: "paperplane.fill") // Красивая системная иконка для отправки
        config.imagePadding = 10
        config.baseBackgroundColor = .primary
        config.baseForegroundColor = .white
        config.buttonSize = .large
        
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.sendButtonTapped()
        })
        button.layer.cornerRadius = 14 // Скругленные углы в стиле iOS
        button.layer.shadowColor = UIColor.primary.cgColor
        button.layer.shadowOpacity = 0.4
        button.layer.shadowRadius = 8
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        return button
    }()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Гарантируем, что invoice установлен
        guard invoice != nil else {
            print("Error: Invoice model not set.")
            // В продакшене тут лучше показать ошибку и закрыть контроллер
            return
        }
        
        setupUI()
        generateAndLoadPDF()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Убеждаемся, что навигационная панель видна, если мы ее скрывали ранее
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .background // Используем ваш кастомный цвет фона
        
        // 1. Настройка Navigation Bar
        title = invoice.invoiceTitle ?? "Invoice Preview"
        
        // Правая кнопка "Edit"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editTapped))
        
        // 2. Добавление Subviews
        view.addSubview(pdfView)
        view.addSubview(sendButton)
        
        // 3. SnapKit Constraints
        
        // Кнопка "Send Invoice" - внизу, с отступом
        sendButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.height.equalTo(56)
        }
        
        // PDF View - занимает все пространство над кнопкой
        pdfView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(sendButton.snp.top).offset(-10)
        }
        
        // Настройка PDFView
        pdfView.autoScales = true // Автоматически подстраивать размер страницы
        pdfView.displayDirection = .vertical // Скроллинг по вертикали
        pdfView.displayMode = .singlePage // Показать одну страницу за раз
        pdfView.backgroundColor = .background // Фон, окружающий PDF документ
        
        // Стиль скроллбара
        pdfView.layer.cornerRadius = 8
        pdfView.clipsToBounds = true
    }
    
    // MARK: - PDF Generation and Loading
    
    private func generateAndLoadPDF() {
        let pdfData = generatePDF()
        if let document = PDFDocument(data: pdfData) {
            pdfView.document = document
        } else {
            // Обработка ошибки
            let alert = UIAlertController(title: "Error", message: "Could not generate PDF document.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    private func generatePDF() -> Data {
        // Стандартный размер страницы A4 (595.2 x 841.8 points)
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            
            // Отступы
            let margin: CGFloat = 40
            var currentY: CGFloat = margin
            let pageWidth = pageRect.width - 2 * margin
            
            // --- 1. Header (Название инвойса, Дата, Due Date) ---
            currentY = drawHeader(pageRect: pageRect, currentY: currentY, margin: margin)
            
            // --- 2. Sender/Company Info (Mock) ---
            currentY = drawCompanyInfo(pageRect: pageRect, currentY: currentY, margin: margin)
            
            // --- 3. Client Info ---
            currentY = drawClientInfo(pageRect: pageRect, currentY: currentY, margin: margin)
            
            // --- 4. Items Table ---
            currentY = drawItemsTable(pageRect: pageRect, currentY: currentY + 30, margin: margin)
            
            // --- 5. Summary / Totals ---
            currentY = drawSummary(pageRect: pageRect, currentY: currentY + 30, margin: margin)
            
            // --- 6. Footer (Payment Notes / Status) ---
            _ = drawFooter(pageRect: pageRect, currentY: 800, margin: margin) // Фиксированное место внизу
        }
        
        return pdfData
    }
    
    // MARK: - PDF Drawing Helper Functions
    
    private func drawHeader(pageRect: CGRect, currentY: CGFloat, margin: CGFloat) -> CGFloat {
        var y = currentY
        let textRect = CGRect(x: margin, y: y, width: pageRect.width - 2 * margin, height: 50)
        
        // Title (Left)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 32),
            .foregroundColor: UIColor.primary
        ]
        let titleText = (invoice.invoiceTitle ?? "INVOICE").uppercased()
        titleText.draw(in: textRect, withAttributes: titleAttributes)
        
        // Status/ID (Right)
        let idText = "INVOICE ID: \(invoice.id.uuidString.prefix(8).uppercased())"
        let statusText = "STATUS: \(invoice.status.uppercased())"
        
        let statusAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.secondaryText
        ]
        
        // Рисуем ID
        let idSize = idText.size(withAttributes: statusAttributes)
        let idRect = CGRect(x: pageRect.width - margin - idSize.width, y: y + 5, width: idSize.width, height: idSize.height)
        idText.draw(in: idRect, withAttributes: statusAttributes)
        
        // Рисуем статус
        let statusSize = statusText.size(withAttributes: statusAttributes)
        let statusRect = CGRect(x: pageRect.width - margin - statusSize.width, y: y + 5 + idSize.height + 5, width: statusSize.width, height: statusSize.height)
        statusText.draw(in: statusRect, withAttributes: statusAttributes)

        
        y += 50
        
        // Draw a separator line
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin, y: y + 5))
        line.addLine(to: CGPoint(x: pageRect.width - margin, y: y + 5))
        UIColor.primaryLight.setStroke()
        line.lineWidth = 2
        line.stroke()
        
        return y + 15
    }
    
    private func drawCompanyInfo(pageRect: CGRect, currentY: CGFloat, margin: CGFloat) -> CGFloat {
        var y = currentY
        let halfWidth = (pageRect.width - 2 * margin) / 2
        
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.secondaryText
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.primaryText
        ]

        let companyName = invoice.client?.clientName ?? ""
        let companyAddress = invoice.client?.address ?? ""
        let companyEmail = invoice.client?.email ?? ""
        
        // Draw Company Name/Header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.primary
        ]
        companyName.draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttributes)
        y += 20
        
        // Draw Address
        companyAddress.draw(at: CGPoint(x: margin, y: y), withAttributes: valueAttributes)
        y += 35 // Multiline
        
        // Draw Email
        companyEmail.draw(at: CGPoint(x: margin, y: y), withAttributes: valueAttributes)
        y += 25
        
        // Draw Dates (on the right side)
        let dateX = margin + halfWidth
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let invoiceDateText = "Invoice Date: \(dateFormatter.string(from: invoice.invoiceDate))"
        let dueDateText = "Due Date: \(dateFormatter.string(from: invoice.dueDate))"
        let statusText = "Status: \(invoice.status)"
        
        let dateLabelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.primaryText
        ]
        
        y = currentY // Сброс Y для правой колонки
        
        // Рисуем даты справа
        invoiceDateText.draw(at: CGPoint(x: dateX, y: y), withAttributes: dateLabelAttributes)
        y += 20
        dueDateText.draw(at: CGPoint(x: dateX, y: y), withAttributes: dateLabelAttributes)
        y += 20
        statusText.draw(at: CGPoint(x: dateX, y: y), withAttributes: dateLabelAttributes)
        
        // Возвращаем максимальный Y
        return max(currentY + 80, y + 20)
    }

    private func drawClientInfo(pageRect: CGRect, currentY: CGFloat, margin: CGFloat) -> CGFloat {
        var y = currentY
        let halfWidth = (pageRect.width - 2 * margin) / 2
        let client = invoice.client
        
        // Заголовок "BILL TO"
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.secondaryText
        ]
        "BILL TO:".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttributes)
        y += 20
        
        guard let client = client, let clientName = client.clientName else {
            "N/A (Client not specified)".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: UIFont.italicSystemFont(ofSize: 12), .foregroundColor: UIColor.error])
            return y + 30
        }
        
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.primaryText
        ]
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.secondaryText
        ]
        
        // Client Name
        clientName.draw(at: CGPoint(x: margin, y: y), withAttributes: nameAttributes)
        y += 20
        
        // Address
        if let address = client.address, !address.isEmpty {
            address.draw(at: CGPoint(x: margin, y: y), withAttributes: detailAttributes)
            y += 35 // Multiline
        }
        
        // Email
        if let email = client.email, !email.isEmpty {
            email.draw(at: CGPoint(x: margin, y: y), withAttributes: detailAttributes)
            y += 15
        }
        
        return y + 10
    }
    
    private func drawItemsTable(pageRect: CGRect, currentY: CGFloat, margin: CGFloat) -> CGFloat {
        var y = currentY
        let pageWidth = pageRect.width - 2 * margin
        let rowHeight: CGFloat = 25
        
        let currency = invoice.currencySymbol
        
        // Координаты колонок (доли от общей ширины)
        let colWidths: [CGFloat] = [0.45, 0.1, 0.15, 0.15, 0.15]
        let headers = ["Item / Description", "Qty", "Unit Price", "Discount", "Line Total"]
        
        var currentX: CGFloat = margin
        var colStarts: [CGFloat] = []
        
        for widthRatio in colWidths {
            colStarts.append(currentX)
            currentX += pageWidth * widthRatio
        }
        
        // --- 1. Draw Table Header ---
        let headerRect = CGRect(x: margin, y: y, width: pageWidth, height: rowHeight)
        UIColor.primaryLight.setFill()
        UIRectFill(headerRect)
        
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.white
        ]
        
        for (index, header) in headers.enumerated() {
            let colStart = colStarts[index]
            let colWidth = pageWidth * colWidths[index]
            let centeredX = colStart + (colWidth / 2) - (header.size(withAttributes: headerAttributes).width / 2)
            
            // Выравнивание: Item/Description - по левому краю, остальные - по центру/правому
            let headerX: CGFloat = (index == 0) ? colStart + 5 : centeredX
            header.draw(at: CGPoint(x: headerX, y: y + 7), withAttributes: headerAttributes)
        }
        y += rowHeight
        
        // --- 2. Draw Items ---
        let itemValueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.primaryText
        ]
        
        for (index, item) in invoice.items.enumerated() {
            let rowRect = CGRect(x: margin, y: y, width: pageWidth, height: rowHeight)
            
            // Чередование фона строк (для лучшей читаемости)
            if index % 2 != 0 {
                UIColor.surface.setFill()
                UIRectFill(rowRect)
            }
            
            let name = item.name ?? "Item (No Name)"
            let qty = String(format: "%.1f %@", item.quantity, String(item.unitType.localized.prefix(1)))
            let unitPrice = "\(currency)\(String(format: "%.2f", item.unitPrice))"
            let discountValue: String
            if item.discountType == .percentage {
                discountValue = String(format: "%.0f%%", item.discountValue)
            } else {
                discountValue = "\(currency)\(String(format: "%.2f", item.discountValue))"
            }
            let lineTotal = "\(currency)\(String(format: "%.2f", item.lineTotal))"
            
            let values = [name, qty, unitPrice, discountValue, lineTotal]
            
            for (colIndex, value) in values.enumerated() {
                let colStart = colStarts[colIndex]
                let colWidth = pageWidth * colWidths[colIndex]
                
                let textX: CGFloat
                
                // Выравнивание по правому краю для чисел, кроме первого столбца
                if colIndex > 0 {
                    let size = value.size(withAttributes: itemValueAttributes)
                    textX = colStart + colWidth - size.width - 5 // 5pt отступ от правого края
                } else {
                    textX = colStart + 5 // 5pt отступ от левого края
                }
                
                value.draw(at: CGPoint(x: textX, y: y + 7), withAttributes: itemValueAttributes)
            }
            
            y += rowHeight
        }
        
        // Draw bottom table border
        let bottomLine = UIBezierPath()
        bottomLine.move(to: CGPoint(x: margin, y: y))
        bottomLine.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
        UIColor.primaryLight.setStroke()
        bottomLine.lineWidth = 1
        bottomLine.stroke()
        
        return y
    }
    
    private func drawSummary(pageRect: CGRect, currentY: CGFloat, margin: CGFloat) -> CGFloat {
        var y = currentY
        let summaryWidth: CGFloat = 180 // Ширина колонки итогов
        let summaryX = pageRect.width - margin - summaryWidth
        let currency = invoice.currencySymbol
        
        // --- Subtotal ---
        y = drawSummaryRow(y: y, x: summaryX, width: summaryWidth, label: "Subtotal:", value: invoice.subtotal, currency: currency, isBold: false)
        
        // --- Tax ---
        y = drawSummaryRow(y: y, x: summaryX, width: summaryWidth, label: "Tax (\(String(format: "%.1f", invoice.taxRate))%):", value: invoice.taxTotal, currency: currency, isBold: false)
        
        // --- Total Discount (if any) ---
        if invoice.discount > 0 {
            y = drawSummaryRow(y: y, x: summaryX, width: summaryWidth, label: "Invoice Discount:", value: -invoice.discount, currency: currency, isBold: false)
        }
        
        // Draw thick separator line
        let line = UIBezierPath()
        line.move(to: CGPoint(x: summaryX, y: y + 2))
        line.addLine(to: CGPoint(x: pageRect.width - margin, y: y + 2))
        UIColor.primary.setStroke()
        line.lineWidth = 2
        line.stroke()
        
        y += 5
        
        // --- Grand Total (Highlight) ---
        y = drawSummaryRow(y: y, x: summaryX, width: summaryWidth, label: "GRAND TOTAL:", value: invoice.grandTotal, currency: currency, isBold: true, fontSize: 16, color: .primary)
        
        return y
    }
    
    private func drawSummaryRow(y: CGFloat, x: CGFloat, width: CGFloat, label: String, value: Double, currency: String, isBold: Bool, fontSize: CGFloat = 12, color: UIColor? = nil) -> CGFloat {
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: isBold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: color ?? UIColor.primaryText
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: isBold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: color ?? UIColor.primaryText
        ]
        
        // Draw Label (Left in Summary Box)
        label.draw(at: CGPoint(x: x, y: y), withAttributes: labelAttributes)
        
        // Draw Value (Right in Summary Box)
        let formattedValue = "\(currency)\(String(format: "%.2f", abs(value)))"
        let size = formattedValue.size(withAttributes: valueAttributes)
        let valueX = x + width - size.width
        formattedValue.draw(at: CGPoint(x: valueX, y: y), withAttributes: valueAttributes)
        
        return y + 20
    }
    
    private func drawFooter(pageRect: CGRect, currentY: CGFloat, margin: CGFloat) -> CGFloat {
        let y = currentY
        
        let footerText = "Thank you for your business. Please remit payment by the due date. Contact us if you have any questions."
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 10),
            .foregroundColor: UIColor.secondaryText,
            .paragraphStyle: paragraphStyle
        ]
        
        let footerRect = CGRect(x: margin, y: y, width: pageRect.width - 2 * margin, height: 40)
        footerText.draw(in: footerRect, withAttributes: attributes)
        
        return y + 40
    }

    // MARK: - Actions
    
    @objc private func editTapped() {
        let editInvoiceViewController = EditInvoiceViewController(invoice: invoice)
        editInvoiceViewController.popEditInvoiceViewControllerHandler = { [weak self] in
            // todo test111 надо вызвать после закрытия editInvoiceViewController обновление экрана с пдф а то он не обновляется
        }
        self.navigationController?.pushViewController(editInvoiceViewController, animated: true)
    }
    
    private func sendButtonTapped() {
        let pdfData = generatePDF()
        
        // Сохраняем PDF временно во временную директорию
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(invoice.invoiceTitle ?? "Invoice").pdf")
        try? pdfData.write(to: tempURL)
        
        // Создаём системный share sheet
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        
        // Для iPad — обязательное требование (иначе краш)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
        
        // Логика отправки PDF по почте - решил лучше: UIActivityViewController
//        let pdfData = generatePDF()
//        
//        if MFMailComposeViewController.canSendMail() {
//            let mail = MFMailComposeViewController()
//            mail.mailComposeDelegate = self
//            mail.setSubject("Invoice: \(invoice.invoiceTitle ?? "Untitled Invoice")")
//            mail.setToRecipients([invoice.client?.email ?? ""]) // Установить получателя, если есть
//            
//            mail.setMessageBody("Dear \(invoice.client?.clientName ?? "Client"),\n\nPlease find attached the invoice for your review. The total amount is \(invoice.currencySymbol)\(String(format: "%.2f", invoice.grandTotal)).\n\nSincerely,\nYour Team", isHTML: false)
//            
//            // Прикрепляем PDF
//            mail.addAttachmentData(pdfData, mimeType: "application/pdf", fileName: "\(invoice.invoiceTitle ?? "Invoice").pdf")
//            
//            present(mail, animated: true)
//        } else {
//            // Если почта не настроена
//            let alert = UIAlertController(title: "Cannot Send Mail", message: "The device is not configured to send mail. PDF data is generated.", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .default))
//            present(alert, animated: true)
//        }
    }
}

// MARK: - MessageUI Delegate (Для закрытия окна почты)

extension InvoiceDetailPDFViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
        
        if let error = error {
            print("Mail composition failed with error: \(error.localizedDescription)")
        } else if result == .sent {
            // Опционально: показать сообщение об успехе
        }
    }
}
