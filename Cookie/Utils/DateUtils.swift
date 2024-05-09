import Foundation

extension Date {
    func isWithinPast(seconds: TimeInterval) -> Bool {
        return timeIntervalSinceNow > -seconds
    }
}
