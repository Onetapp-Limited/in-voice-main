import DGCharts
import Foundation

class DateAxisValueFormatter: AxisValueFormatter {
    private let dates: [Date]
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // Пример: "Ноя 6"
        formatter.locale = Locale.current // Для локализации
        return formatter
    }()

    init(dates: [Date]) {
        self.dates = dates
    }

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value.rounded())
        
        guard index >= 0, index < dates.count else {
            return ""
        }
        
        return dateFormatter.string(from: dates[index])
    }
}
