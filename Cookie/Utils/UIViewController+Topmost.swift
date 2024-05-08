import UIKit

extension UIViewController {
    var topmostPresentedViewController: UIViewController {
        return presentedViewController?.topmostPresentedViewController ?? self
    }
}

private extension UIScene {
    var activityScore: Int {
        switch activationState {
        case .foregroundActive: return 3
        case .foregroundInactive: return 2
        case .background: return 1
        default: return 0
        }
    }
}

extension UIApplication {
    var activeWindowScene: UIWindowScene? {
        self
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .sorted { $0.activityScore > $1.activityScore }.first
    }
    var activeWindow: UIWindow? {
        guard let window = activeWindowScene?.keyWindow ?? activeWindowScene?.windows.last else {
                  return nil
              }
        return window
    }
    var viewControllerForModalPresentation: UIViewController? {
        return activeWindow?.rootViewController?.topmostPresentedViewController
    }
}

extension UIWindow {
    var topmostViewController: UIViewController? {
        rootViewController?.topmostPresentedViewController
    }
}
