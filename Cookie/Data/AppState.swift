import Foundation

struct AppState: Equatable, Codable {
    var recipes = [String: Recipe]()
    var timers = [InProgressTimer]()
    var voiceAssistantActive = false
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
}
