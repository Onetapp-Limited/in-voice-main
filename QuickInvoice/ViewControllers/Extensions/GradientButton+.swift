import UIKit
import SnapKit

class GradientButton: UIButton {
    private var gradientLayer: CAGradientLayer!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if gradientLayer == nil {
            setupGradient()
        }
        gradientLayer.frame = bounds
        layer.cornerRadius = bounds.height / 2 // Делаем кнопку скругленной по высоте
        layer.masksToBounds = true
    }
    
    private func setupGradient() {
        gradientLayer = CAGradientLayer()
        
        // Используем два оттенка для градиента.
        // Здесь предполагаем, что у вас есть два кастомных цвета.
        let startColor = UIColor.primary.cgColor
        // Для демонстрации, если нет 'primaryDark', используем слегка затемненный primary
        let endColor = UIColor.primary.withAlphaComponent(0.8).cgColor
        
        gradientLayer.colors = [startColor, endColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        
        layer.insertSublayer(gradientLayer, at: 0)
    }
}
