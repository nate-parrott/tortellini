import UIKit

extension UIApplication {
    func ensureModalsDismissed(_ callback: @escaping () -> Void) {
        if let root = keyWindow?.rootViewController, root.presentedViewController != nil {
            root.dismiss(animated: false) {
                callback()
            }
        } else {
            callback()
        }
    }
}
