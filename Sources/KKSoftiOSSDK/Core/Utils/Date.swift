import Foundation

extension Date {
    func startOf2AMDay() -> Date {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day], from: self)
        return calendar.date(bySettingHour: 2, minute: 0, second: 0, of: calendar.date(from: comps)!)!
    }
}
