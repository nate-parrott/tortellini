import Foundation

extension String {
    var cleanedUp: String {
        let subs: [String: String] = [
            "1/2": "½",
            "1/4": "¼",
            "3/4": "¾",
        ]

        var s = self
        for (orig, sub) in subs {
            s = s.replacingOccurrences(of: orig, with: sub)
        }
        return s
    }
}
