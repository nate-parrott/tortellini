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
        for timer in timers {
            let content = UNMutableNotificationContent()
            content.title = "Timer Done"
            content.body = timer.original.asText + ""
            content.sound = UNNotificationSound.default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timer.remainingSeconds), repeats: false)
            let request = UNNotificationRequest(identifier: timer.id, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request)
        }
    }
}

//struct InProgressTimer: Equatable, Codable, Identifiable {
//    var id: String
//    var recipeId: String
//    var original: CookTimer
//    var repeatedAlready: Int
//    var started: Date
//    
//    var remainingSeconds: Int ...
//}

// struct CookTimer: Equatable, Codable {
//     var asText: String
//     var seconds: Int
//     var repeats: Int?
// }
