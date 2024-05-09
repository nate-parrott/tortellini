import Foundation

@MainActor
class VoiceAssistant {
    var on = false {
        didSet {
            if on != oldValue {
                // todo
            }
        }
    }
}
