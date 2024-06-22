import UIKit
import Foundation
import Combine

class LocalNotificationManager {
    static let shared = LocalNotificationManager()

    var subscriptions = Set<AnyCancellable>()

    init() {
        AppStore.shared.publisher.map(\.timers).removeDuplicates()
            .sink { [weak self] timers in
                self?.createNotifs(timers: timers)
            }
            .store(in: &subscriptions)
    }

    func createNotifs(timers: [InProgressTimer]) {
        // Cancel existing, then create new
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let active = timers.filter { $0.remainingSeconds >= 2 }
        guard active.count > 0 else { return }

        Task { @MainActor in
            let granted = await getNotifPermission()
            if !granted { return }

            for timer in timers where timer.remainingSeconds > 2 {
                let content = UNMutableNotificationContent()
                content.title = "Timer Done"
                content.body = timer.original.asText + ""
                content.sound = UNNotificationSound.default

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timer.remainingSeconds), repeats: false)
                let request = UNNotificationRequest(identifier: timer.id, content: content, trigger: trigger)

                try? await UNUserNotificationCenter.current().add(request)
            }
        }
    }

    func getNotifPermission() async -> Bool {
        if DefaultsKeys.hasRequestedNotifPermission.boolValue {
            return true
        }

        let prompt = PromptDialogModel(
            title: "Get notified when the timer stops",
            message: "You'll need to accept notifications permissions. No other notifications will be sent!",
            cancellable: false, 
            hasTextField: false
        )

        let res = await prompt.run()
//        if res.cancelled {
//            return false
//        }

        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false

        DefaultsKeys.hasRequestedNotifPermission.boolValue = true

        return granted
    }
}

// struct PromptDialogModel: Equatable {
//     var title: String
//     var message: String
//     var cancellable: Bool
//     var hasTextField: Bool
//     var defaultText = ""
// }

// struct PromptDialogResult: Equatable {
//     var text: String
//     var cancelled: Bool
// }

// extension PromptDialogModel {
//     func run() async -> PromptDialogResult {
//         let (ok, text) = await UIApplication.shared.prompt(title: title, message: message, showTextField: hasTextField, placeholder: nil)
//         return .init(text: text ?? "", cancelled: !ok)
//     }
// }

