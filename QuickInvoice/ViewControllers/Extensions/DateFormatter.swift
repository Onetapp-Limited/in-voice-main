import UIKit

extension DateFormatter {
    static let invoice: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy" 
        return f
    }()
    
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy" // Oct 2025
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}
