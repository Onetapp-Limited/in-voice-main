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

    // MARK: - Table View Delegate Overrides
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("Edit item at \(indexPath.row)")
        
        let itemToEdit = currentInvoice.items[indexPath.row]
        
        // test111 item не редактируется сейчас потом можно доделать
        // Предположим, что NewInvoiceItemViewController может принимать элемент для редактирования
        // Если NewInvoiceItemViewController не имеет такого инициализатора,
        // его нужно будет создать/обновить в реальном приложении.
        // Для примера, используем тот же класс и передаем существующий элемент
        
        let editItemVC = NewInvoiceItemViewController(item: itemToEdit) // Предполагаем, что такой init существует
        editItemVC.delegate = self
        let navController = UINavigationController(rootViewController: editItemVC)
        present(navController, animated: true)
    }
}

