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
        // TODO
    }
}
