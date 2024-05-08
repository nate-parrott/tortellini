import UIKit

extension UIApplication {
    private func prompt(title: String?, message: String?, placeholder: String?, callback: @escaping (String?) -> Void) {
        guard let vc = viewControllerForModalPresentation else {
            callback(nil)
            return
        }
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        dialog.addTextField { field in
            field.placeholder = placeholder
        }
        dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            callback(nil)
        }))
        dialog.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
            let text = dialog.textFields!.first!.text
            callback(text)
        }))
        vc.present(dialog, animated: true, completion: nil)
    }

    func prompt(title: String?, message: String?, placeholder: String?) async -> String? {
        return await withCheckedContinuation { cont in
            Task {
                await MainActor.run {
                    self.prompt(title: title, message: message, placeholder: placeholder) { res in
                        cont.resume(returning: res)
                    }
                }
            }
        }
    }

    func showAlert(_ alert: UIAlertController) {
        viewControllerForModalPresentation?.present(alert, animated: true, completion: nil)
    }
}
