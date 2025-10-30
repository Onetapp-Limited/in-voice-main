import UIKit
import SnapKit

class EditEstimateViewController: NewEstimateViewController {
    
    init(invoice: Invoice) {
        super.init(nibName: nil, bundle: nil)
        self.currentInvoice = invoice
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Edit Invoice"
        saveButton.setTitle("Update Estimate", for: .normal)
    }
    
    @objc override func saveInvoiceTapped() {
        currentInvoice.invoiceTitle = titleTextField.text
        currentInvoice.totalAmount = totalAmountLabel.text ?? ""
        
        do {
            try estimateService?.updateEstimate(mapInvoiceToEstimate(currentInvoice))
            print("Invoice updated successfully!")
            popEditInvoiceViewControllerHandler?(currentInvoice)
        } catch {
            print("Error updating invoice: \(error)")
        }
             
        dismissSelf()
    }
}

