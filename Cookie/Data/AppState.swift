import Foundation

struct AppState: Equatable, Codable {
    var recipes = [String: Recipe]()
    var voiceAssistantActive = false
    var lastActiveRecipe: String?

    var timers = [InProgressTimer]()
    var focusedTimerId: String?
}

class AppStore: DataStore<AppState> {
    static let shared = AppStore(persistenceKey: "CookieAppStore", defaultModel: .stub, queue: .main)

    override func processModelAfterLoad(model: inout AppState) {
        for id in model.recipes.keys {
            model.recipes[id]?.generating = nil
        }
    }
}

extension AppState {
    static var stub: AppState {
        let recipe = Recipe.stub
        var recipe2 = recipe
        recipe2.id = "recipe2"
        return AppState(recipes: [recipe.id: recipe, recipe2.id: recipe2])
    }
}

struct InProgressTimer: Equatable, Codable, Identifiable {
    var id: String
    var recipeId: String
    var original: CookTimer
    var repeatedAlready: Int
    var started: Date
    var unitPos: CGPoint = .init(x: 0, y: 1) // only valid vals are 0 and 1

    var remainingRepeats: Int {
        max(0, (original.repeats ?? 1) - repeatedAlready - 1)
    }

    var remainingSeconds: Int {
        get {
            let elapsedSeconds = Int(Date().timeIntervalSince(started))
            let remainingSecs = max(0, original.seconds - elapsedSeconds)
            return remainingSecs
        } set {
            // elapsed = now - start
            // remaining = duration - elapsed
            // remaining = duration - (now - start)
            // remaining = start + duration - now
            // remaining + now - duration = start
            started = Date(timeIntervalSinceReferenceDate: TimeInterval(newValue) + Date.timeIntervalSinceReferenceDate - TimeInterval(original.seconds))
        }
    }

    var remainingTime: String {
        // Format like 5:21 or 1:00:00
        if remainingSeconds == 0 {
            return "00:00"
        }
        let formatter = DateComponentsFormatter()
        if original.seconds < 3600 {
            formatter.allowedUnits = [.minute, .second]
        } else {
            formatter.allowedUnits = [.hour, .minute, .second]
        }
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: TimeInterval(remainingSeconds)) ?? "0:00"
    }

    var isFinished: Bool {
        let elapsedSeconds = Int(Date().timeIntervalSince(started))
        let remainingSecs = max(0, original.seconds - elapsedSeconds)
        return remainingSecs == 0
    }

    var totalTime: String {
        let formatter = DateComponentsFormatter()
        if original.seconds < 3600 {
            formatter.allowedUnits = [.minute, .second]
        } else {
            formatter.allowedUnits = [.hour, .minute, .second]
        }
        formatter.unitsStyle = .positional
        return formatter.string(from: TimeInterval(original.seconds)) ?? "0:00"
    }

    var asContextForLLM: String {
        let remainingRepeats = max(0, (original.repeats ?? 1) - repeatedAlready)
        return """
        <timer label='\(original.asText)' totalTime='\(totalTime)s' remainingTime='\(remainingTime)s' totalRepeats="\(original.repeats ?? 1)" remainingRepeats="\(remainingRepeats)" />
        """
    }
}
