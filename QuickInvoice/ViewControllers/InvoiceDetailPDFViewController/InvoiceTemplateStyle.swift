import UIKit
import PDFKit

// MARK: - Template Definition
enum InvoiceTemplateStyle: String, CaseIterable {
    case modern = "Modern"
    case classic = "Classic"
    case minimal = "Minimal"
    case vibrant = "Vibrant"
    case tealAccent = "Teal"
    case goldTheme = "Gold"
    case boxed = "Boxed"

    var accentColor: UIColor {
        switch self {
        case .modern: return UIColor.systemBlue
        case .classic: return UIColor.black
        case .minimal: return UIColor.systemGray
        case .vibrant: return UIColor.systemRed
        case .tealAccent: return UIColor(red: 0.1, green: 0.6, blue: 0.6, alpha: 1.0)
        case .goldTheme: return UIColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1.0)
        case .boxed: return UIColor.systemGreen
        }
    }
    
    var secondaryColor: UIColor {
        switch self {
        case .modern: return UIColor.systemBlue.withAlphaComponent(0.1)
        case .classic: return UIColor.systemGray.withAlphaComponent(0.2)
        case .minimal: return UIColor.systemGray.withAlphaComponent(0.05)
        case .vibrant: return UIColor.systemRed.withAlphaComponent(0.1)
        case .tealAccent: return accentColor.withAlphaComponent(0.08)
        case .goldTheme: return accentColor.withAlphaComponent(0.15)
        case .boxed: return accentColor.withAlphaComponent(0.1)
        }
    }
    
    var isSerifFont: Bool {
        switch self {
        case .classic, .goldTheme: return true
        default: return false
        }
    }
    
    var tableStripeColor: UIColor {
        return secondaryColor
    }
    
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
