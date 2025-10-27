import UIKit

extension DateFormatter {
    static let invoice: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy" 
        return f
    }()
}
