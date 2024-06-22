import UIKit

extension UIApplication {
    private func prompt(title: String?, message: String?, showTextField: Bool, placeholder: String?, callback: @escaping (Bool, String?) -> Void) {
        guard let vc = viewControllerForModalPresentation else {
            callback(false, nil)
            return
        }
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if showTextField {
            dialog.addTextField { field in
                field.placeholder = placeholder
            }
        }
        dialog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            callback(false, nil)
        }))
        dialog.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
            let text = dialog.textFields?.first?.text
            callback(true, text)
        }))
        vc.present(dialog, animated: true, completion: nil)
    }

    func prompt(title: String?, message: String?, showTextField: Bool, placeholder: String?) async -> (ok: Bool, text: String?) {
        return await withCheckedContinuation { cont in
            Task {
                await MainActor.run {
                    self.prompt(title: title, message: message, showTextField: showTextField, placeholder: placeholder) { ok, text in
                        cont.resume(returning: (ok, text))
                    }
                }
            }
        }
    }

    func showAlert(_ alert: UIAlertController) {
        viewControllerForModalPresentation?.present(alert, animated: true, completion: nil)
    }
}

struct PromptDialogModel: Equatable {
    var title: String
    var message: String
    var cancellable: Bool
    var hasTextField: Bool
    var defaultText = ""
}

struct PromptDialogResult: Equatable {
    var text: String
    var cancelled: Bool
}

func prompt(question: String, title: String = "Question") async -> String? {
    let res = await PromptDialogModel(title: title, message: question, cancellable: true, hasTextField: true).run()
    return res.cancelled ? nil : res.text
}

extension PromptDialogModel {
    func run() async -> PromptDialogResult {
        let (ok, text) = await UIApplication.shared.prompt(title: title, message: message, showTextField: hasTextField, placeholder: nil)
        return .init(text: text ?? "", cancelled: !ok)
    }
}

