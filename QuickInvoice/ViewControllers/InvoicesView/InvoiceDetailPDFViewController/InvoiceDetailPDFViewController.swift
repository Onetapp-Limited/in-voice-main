import UIKit
import SnapKit
import PDFKit
import MessageUI

class InvoiceDetailPDFViewController: UIViewController {

    // MARK: - Properties
    
    var invoice: Invoice?
    private let pdfView = PDFView()
    
    // MARK: - UI Elements
    
    private lazy var sendButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Send Invoice (PDF)"
        config.image = UIImage(systemName: "paperplane.fill")
        config.imagePadding = 10
        // Использование предполагаемых кастомных цветов
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
            // В случае ошибки, лучше закрыть контроллер
            dismiss(animated: true)
            return
        }
        
        setupUI()
        generateAndLoadPDF()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup
    
    private func setupUI() {
        // Использование предполагаемого кастомного цвета
        view.backgroundColor = .background
        
        title = invoice?.invoiceTitle ?? "Invoice Preview"
        
        // Правая кнопка "Edit" (предполагаем наличие EditInvoiceViewController)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editTapped))
        
        view.addSubview(pdfView)
        view.addSubview(sendButton)
        
        sendButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.height.equalTo(56)
        }
        
        pdfView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(sendButton.snp.top).offset(-10)
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
        let pdfData = generatePDF(for: invoice)
        
        if let document = PDFDocument(data: pdfData) {
            pdfView.document = document
        } else {
            let alert = UIAlertController(title: "Error", message: "Could not generate PDF document.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    private func generatePDF(for invoice: Invoice) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            
            let margin: CGFloat = 40
            var currentY: CGFloat = margin
            
            // --- 1. Header (Title, ID) ---
            currentY = drawHeader(pageRect: pageRect, currentY: currentY, margin: margin, invoice: invoice)
            
            // --- 2. Sender Info & Dates/Status (Фикс дублирования) ---
            currentY = drawCompanyInfo(pageRect: pageRect, currentY: currentY + 10, margin: margin, invoice: invoice)
            
            // --- 3. Client Info (BILL TO) ---
            currentY = drawClientInfo(pageRect: pageRect, currentY: currentY + 30, margin: margin, invoice: invoice)
            
            // --- 4. Items Table (с учетом новых полей) ---
            currentY = drawItemsTable(pageRect: pageRect, currentY: currentY + 30, margin: margin, invoice: invoice)
            
            // --- 5. Summary / Totals (с учетом новых вычислений) ---
            currentY = drawSummary(pageRect: pageRect, currentY: currentY + 30, margin: margin, invoice: invoice)
            
            // --- 6. Footer (Payment Notes / Status) ---
            _ = drawFooter(pageRect: pageRect, currentY: 800, margin: margin) // Фиксированное место внизу
        }
        
        return pdfData
    }
    
    // MARK: - PDF Drawing Helper Functions
    
    private func drawHeader(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice) -> CGFloat {
        var y = currentY
        let textRect = CGRect(x: margin, y: y, width: pageRect.width - 2 * margin, height: 50)
        
        // Title (Left)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 32),
            .foregroundColor: UIColor.primary
        ]
        let titleText = (invoice.invoiceTitle ?? "INVOICE").uppercased()
        titleText.draw(in: textRect, withAttributes: titleAttributes)
        
        // ID (Right)
        let idText = "INVOICE ID: \(invoice.id.uuidString.prefix(8).uppercased())"
        
        let idAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
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
        UIColor.primary.setStroke()
        line.lineWidth = 3
        line.stroke()
        
        return y + 15
    }
    
    /**
     Отрисовывает информацию об Отправителе (Mock) слева и Важные даты/статус справа.
     */
    private func drawCompanyInfo(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice) -> CGFloat {
        var y = currentY
        let halfWidth = (pageRect.width - 2 * margin) / 2
        
        // --- LEFT SIDE: SENDER (Mock Info) ---
        let senderHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.primary
        ]
        let senderDetailAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.primaryText
        ]
        
        // Draw Sender Header (Mock)
        "FROM:".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: UIColor.secondaryText])
        y += 20
        
        // todo test111 это потом брать из общих настроек:
        // Placeholder Company Info (фиктивные данные, т.к. нет модели Компании)
        "My Company Name Inc.".draw(at: CGPoint(x: margin, y: y), withAttributes: senderHeaderAttributes)
        y += 20
        "123 Business Blvd, Suite 400".draw(at: CGPoint(x: margin, y: y), withAttributes: senderDetailAttributes)
        y += 15
        "City, State, 10001".draw(at: CGPoint(x: margin, y: y), withAttributes: senderDetailAttributes)
        y += 15
        "contact@mycompany.com".draw(at: CGPoint(x: margin, y: y), withAttributes: senderDetailAttributes)
        
        let leftColumnMaxY = y + 10
        
        // --- RIGHT SIDE: Dates, Status, Currency ---
        let dateX = margin + halfWidth
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let invoiceDateText = "Invoice Date: \(dateFormatter.string(from: invoice.invoiceDate))"
        let dueDateText = "Due Date: \(dateFormatter.string(from: invoice.dueDate))"
        let statusText = "Status: \(invoice.status.rawValue)"
        let currencyText = "Currency: \(invoice.currency.code) (\(invoice.currencySymbol))"
        
        let dateLabelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.primaryText
        ]
        
        var rightY = currentY + 20 // Start Y for right column after "FROM:" header
        
        // Рисуем даты справа
        invoiceDateText.draw(at: CGPoint(x: dateX, y: rightY), withAttributes: dateLabelAttributes)
        rightY += 20
        dueDateText.draw(at: CGPoint(x: dateX, y: rightY), withAttributes: dateLabelAttributes)
        rightY += 20
        statusText.draw(at: CGPoint(x: dateX, y: rightY), withAttributes: dateLabelAttributes)
        rightY += 20
        currencyText.draw(at: CGPoint(x: dateX, y: rightY), withAttributes: dateLabelAttributes)

        // Возвращаем максимальный Y
        return max(leftColumnMaxY, rightY + 10)
    }

    /**
     Отрисовывает информацию о Клиенте (Получателе)
     */
    private func drawClientInfo(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice) -> CGFloat {
        var y = currentY
        let client = invoice.client
        
        // Заголовок "BILL TO"
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.secondaryText
        ]
        "BILL TO:".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttributes)
        y += 20
        
        guard let client = client, let clientName = client.clientName, !clientName.isEmpty else {
            "N/A (Client not specified)".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: UIFont.italicSystemFont(ofSize: 12), .foregroundColor: UIColor.secondaryText])
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

        // Client Type (если не New Client)
        if client.clientType != .newClient {
            let typeText = "Type: \(client.clientType.localized)"
            typeText.draw(at: CGPoint(x: margin, y: y), withAttributes: detailAttributes)
            y += 15
        }
        
        return y + 10
    }
    
    /**
     Отрисовывает таблицу позиций инвойса.
     */
    private func drawItemsTable(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice) -> CGFloat {
        var y = currentY
        let pageWidth = pageRect.width - 2 * margin
        let rowHeight: CGFloat = 35 // Увеличена высота для описания
        
        let currencySymbol = invoice.currencySymbol
        
        // Координаты колонок (доли от общей ширины)
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
        UIColor.primary.setFill() // Используем primary для заголовка
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
            header.draw(at: CGPoint(x: headerX, y: y + 10), withAttributes: headerAttributes)
        }
        y += rowHeight
        
        // --- 2. Draw Items ---
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.primaryText
        ]
        let descAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.secondaryText
        ]
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.primaryText
        ]
        
        for (index, item) in invoice.items.enumerated() {
            // TODO: Реализовать логику разбиения на страницы при необходимости
            
            let rowRect = CGRect(x: margin, y: y, width: pageWidth, height: rowHeight)
            
            // Чередование фона строк
            if index % 2 != 0 {
                UIColor.surface.setFill()
                UIRectFill(rowRect)
            }
            
            // Расчет и форматирование значений
            let qtyUnit = item.unitType == .item ? "" : " \(item.unitType.localized.prefix(1))"
            let qty = String(format: "%.1f%@", item.quantity, qtyUnit)
            let unitPrice = "\(currencySymbol)\(String(format: "%.2f", item.unitPrice))"
            let discountValueString: String
            
            if item.discountType == .percentage {
                // discountValue в модели - это доля (0.0 - 1.0)
                discountValueString = String(format: "%.0f%%", item.discountValue * 100)
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
                
                if colIndex == 0 {
                    // Name
                    tuple.0.draw(at: CGPoint(x: colStart + 5, y: y + 4), withAttributes: nameAttributes)
                    
                    // Description (Multiline support in restricted area)
                    if !tuple.1!.isEmpty {
                        let descRect = CGRect(x: colStart + 5, y: y + 18, width: colWidth - 10, height: 15)
                        tuple.1!.draw(in: descRect, withAttributes: descAttributes)
                    }
                    
                } else {
                    // Other columns: Qty, Prices, Discount, Total (Right-aligned)
                    let value = tuple.0
                    let size = value.size(withAttributes: valueAttributes)
                    let textX = colStart + colWidth - size.width - 5 // 5pt отступ от правого края
                    
                    value.draw(at: CGPoint(x: textX, y: y + (rowHeight - size.height) / 2), withAttributes: valueAttributes)
                }
            }
            
            // Draw horizontal line separator
            let separator = UIBezierPath()
            separator.move(to: CGPoint(x: margin, y: y + rowHeight))
            separator.addLine(to: CGPoint(x: pageRect.width - margin, y: y + rowHeight))
            UIColor.border.setStroke()
            separator.lineWidth = 0.5
            separator.stroke()
            
            y += rowHeight
        }
        
        return y
    }
    
    /**
     Отрисовывает итоги (Subtotal, Tax, Discount, Grand Total) используя вычисляемые свойства модели.
     */
    private func drawSummary(pageRect: CGRect, currentY: CGFloat, margin: CGFloat, invoice: Invoice) -> CGFloat {
        var y = currentY
        let summaryWidth: CGFloat = 180
        let summaryX = pageRect.width - margin - summaryWidth
        let currencySymbol = invoice.currencySymbol
        
        // --- Subtotal ---
        y = drawSummaryRow(y: y, x: summaryX, width: summaryWidth, label: "Subtotal:", value: invoice.subtotal, currencySymbol: currencySymbol, isBold: false)
        
        // --- Tax ---
        let taxRateDisplay = String(format: "%.1f", invoice.taxRate * 100) // Отображаем в процентах
        y = drawSummaryRow(y: y, x: summaryX, width: summaryWidth, label: "Tax (\(taxRateDisplay)%):", value: invoice.taxTotal, currencySymbol: currencySymbol, isBold: false)
        
        // --- Total Discount (на инвойс) ---
        if invoice.discount > 0 {
            // Передаем отрицательное значение, чтобы показать вычитание
            y = drawSummaryRow(y: y, x: summaryX, width: summaryWidth, label: "Invoice Discount:", value: -invoice.discount, currencySymbol: currencySymbol, isBold: false)
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
        y = drawSummaryRow(y: y, x: summaryX, width: summaryWidth, label: "GRAND TOTAL: ", value: invoice.grandTotal, currencySymbol: currencySymbol, isBold: true, fontSize: 16, color: .primary)
        
        return y
    }
    
    /**
     Вспомогательная функция для отрисовки одной строки итогов.
     */
    private func drawSummaryRow(y: CGFloat, x: CGFloat, width: CGFloat, label: String, value: Double, currencySymbol: String, isBold: Bool, fontSize: CGFloat = 12, color: UIColor? = nil) -> CGFloat {
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
        // Используем abs(value), так как знак уже подразумевается для Discount
        let formattedValue = "\(currencySymbol)\(String(format: "%.2f", abs(value)))"
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
        guard let invoice = invoice else { return }

        // Предполагаем, что класс EditInvoiceViewController существует
        let editInvoiceViewController = EditInvoiceViewController(invoice: invoice)
        
        // Обновление PDF после редактирования
        editInvoiceViewController.popEditInvoiceViewControllerHandler = { [weak self] updatedInvoice in
            self?.invoice = updatedInvoice
            self?.generateAndLoadPDF()
            self?.title = self?.invoice?.invoiceTitle ?? "Invoice Preview"
        }
        self.navigationController?.pushViewController(editInvoiceViewController, animated: true)
    }
    
    private func sendButtonTapped() {
        guard let invoice = invoice else { return }
        let pdfData = generatePDF(for: invoice)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(invoice.invoiceTitle ?? "Invoice").pdf")
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

// MARK: - MessageUI Delegate (Для закрытия окна почты)

extension InvoiceDetailPDFViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
        
        if let error = error {
            print("Mail composition failed with error: \(error.localizedDescription)")
        }
    }
}
