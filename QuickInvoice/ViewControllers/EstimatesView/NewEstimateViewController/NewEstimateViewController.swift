import UIKit
import SnapKit

class NewEstimateViewController: NewInvoiceViewController {
    
    var estimateService: EstimateService? {
        do {
            return try EstimateService()
        } catch {
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "New Estimate"
        saveButton.setTitle("Save Estimate", for: .normal)
        titleTextField.placeholder = String(currentInvoice.id.description.prefix(8))
        titleTextField.text = String(currentInvoice.id.description.prefix(8))
        datesCard.isHidden = true
        statusCard.isHidden = true
        currentInvoice.creationDate = Date()
        currentInvoice.status = .draft
        
        itemsHeaderLabel.snp.remakeConstraints { make in
            make.top.equalTo(clientCard.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }
    
    @objc override func saveInvoiceTapped() {
        currentInvoice.invoiceTitle = titleTextField.text
        currentInvoice.totalAmount = totalAmountLabel.text ?? ""
        updateInvoiceSummary()

        do {
            try estimateService?.save(estimate: mapInvoiceToEstimate(currentInvoice))
            print("Invoice Saved!")
        } catch {
            print("Error saving invoice: \(error)")
        }
              
        dismissSelf()
    }
    
    func mapInvoiceToEstimate(_ invoice: Invoice) -> Estimate {
        return Estimate(
            id: invoice.id,
            estimateTitle: invoice.invoiceTitle,
            client: invoice.client,
            items: invoice.items,
            taxRate: invoice.taxRate,
            discount: invoice.discount,
            discountType: invoice.discountType,
            creationDate: invoice.creationDate,
            status: invoice.status,
            currency: invoice.currency,
            totalAmount: invoice.totalAmount
        )
    }
}

