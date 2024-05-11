import Foundation

struct Recipe: Equatable, Codable, Identifiable {
    var id: String
    var url: URL?
    var added: Date
    var title: String
    var text: String // e.g. markdown, or extracted data
    var image: URL?
    var parsed: ParsedRecipe?
    var movedToFront: Date?
    var generating: Bool?

    var sortDate: Date {
        movedToFront ?? added
    }
}

struct ParsedRecipe: Equatable, Codable {
    var title: String
    var description: String?
    var steps: [Step]
    var ingredients: [Ingredient]
    var yield: String?
    var cookTime: String?
    var prepTime: String?
}

struct Ingredient: Equatable, Codable {
    var emoji: String
    var text: String
    var missingInfo: String?
}

struct Step: Equatable, Codable {
    var title: String
    var text: String // Initially, write like this
    var formattedText: [FormattedText]?

    enum FormattedText: Equatable, Codable {
        case plain(String)
        case bold(String)
        case ingredient(Ingredient)
        case timer(CookTimer)
    }
}

struct CookTimer: Equatable, Codable {
    var asText: String
    var seconds: Int
    var repeats: Int?
}
