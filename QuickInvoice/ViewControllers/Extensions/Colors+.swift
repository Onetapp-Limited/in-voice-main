import UIKit

// MARK: - UIColor Extension for Asset Colors
extension UIColor {
    
    // MARK: - Dynamic Color Helper
    // Эта функция загружает именованные цвета из Asset Catalog.
    private static func dynamicColor(_ name: String) -> UIColor {
        // Используем guard let для безопасной загрузки.
        guard let color = UIColor(named: name) else {
            // В случае ошибки, выводим фатальное сообщение, но возвращаем
            // нейтральный цвет (например, красный), чтобы увидеть проблему.
            fatalError("Fatal Error: Color asset '\(name)' not found in Asset Catalog.")
        }
        return color
    }
    
    // MARK: - Primary Colors
    static var primary: UIColor { dynamicColor("Primary") }
    static var primaryLight: UIColor { dynamicColor("PrimaryLight") }
    static var primaryDark: UIColor { dynamicColor("PrimaryDark") }
    static var secondary: UIColor { dynamicColor("Secondary") }
    static var accent: UIColor { dynamicColor("Accent") }
    
    // MARK: - Background Colors
    static var background: UIColor { dynamicColor("Background") }
    static var backgroundSecondary: UIColor { dynamicColor("BackgroundSecondary") }
    static var surface: UIColor { dynamicColor("Surface") }
    
    // MARK: - Text Colors
    static var primaryText: UIColor { dynamicColor("TextPrimary") }
    static var secondaryText: UIColor { dynamicColor("TextSecondary") }
    static var tertiaryText: UIColor { dynamicColor("TextTertiary") }
    
    // MARK: - Status Colors
    static var success: UIColor { dynamicColor("Success") }
    static var warning: UIColor { dynamicColor("Warning") }
    static var error: UIColor { dynamicColor("Error") }

    // MARK: - Icon Colors
    static var iconPrimary: UIColor { dynamicColor("IconPrimary") }
    static var iconSecondary: UIColor { dynamicColor("IconSecondary") }
    
    // MARK: - Border Colors
    static var border: UIColor { dynamicColor("Border") }
}

// ----------------------------------------------------------------------

// MARK: - UIColor Extension for Hex Support (Оставляем как есть, для удобства)
extension UIColor {
    
    // Создание UIColor из Hex-строки
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        // ... (остальная логика Hex-конвертации)
        
        var rgb: UInt64 = 0
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = alpha
        
        let length = hexSanitized.count
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        switch length {
        case 3:
            r = CGFloat((rgb & 0xF00) >> 8) / 15.0
            g = CGFloat((rgb & 0x0F0) >> 4) / 15.0
            b = CGFloat(rgb & 0x00F) / 15.0
        case 6:
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        case 8:
            a = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            r = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x000000FF) / 255.0
        default:
            self.init(red: 0, green: 0, blue: 0, alpha: 0)
            return
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
