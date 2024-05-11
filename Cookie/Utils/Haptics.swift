import UIKit

class Haptics {
    static let shared = Haptics()

    init() {}

    private let selection = UISelectionFeedbackGenerator()
    private let notif = UINotificationFeedbackGenerator()
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let type = UIImpactFeedbackGenerator(style: .light)

    func performSelectionHaptic() {
        selection.selectionChanged()
    }

    func performTypeHaptic() {
        type.impactOccurred()
    }

    func performSuccessHaptic() {
        notif.notificationOccurred(.success)
    }

    func performFailureHaptic() {
        notif.notificationOccurred(.error)
    }

    func performWarningHaptic() {
        notif.notificationOccurred(.warning)
    }

    func performSoftHaptic() {
        soft.impactOccurred()
    }
}
