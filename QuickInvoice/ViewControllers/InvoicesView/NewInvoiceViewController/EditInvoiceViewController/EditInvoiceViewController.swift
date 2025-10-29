import UIKit
import SnapKit

class EditInvoiceViewController: NewInvoiceViewController {

    var popEditInvoiceViewControllerHandler: ((Invoice) -> Void)?
    
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
        saveButton.setTitle("Update Invoice", for: .normal)
    }
    
    @objc override func saveInvoiceTapped() {
        currentInvoice.invoiceTitle = titleTextField.text
        currentInvoice.totalAmount = totalAmountLabel.text ?? ""
        
        print("--- Updating Invoice \(currentInvoice.id) ---")
        print("Title: \(currentInvoice.invoiceTitle ?? "")")
        print("Total: \(totalAmountLabel.text ?? "")")
        print("----------------------")
        
        do {
            try invoiceService?.updateInvoice(currentInvoice)
            print("Invoice updated successfully!")
            popEditInvoiceViewControllerHandler?(currentInvoice)
        } catch {
            print("Error updating invoice: \(error)")
        }
             
        dismissSelf()
    }
}

