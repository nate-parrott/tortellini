import Foundation

extension Recipe {
    static let stub = Recipe(
        id: "stub",
        url: URL(string: "https://nytimes.com")!,
        added: Date(),
        title: "Delicious and Simple Weeknight Pasta | NYTimes",
        text: "?????",
        image: nil,
        parsed: ParsedRecipe(
            title: "Delicious and Simple Weeknight Pasta",
            description: "This pasta dish puts all others to shame, with its simple weeknight joie de vivre.",
            steps: [
                .init(title: "Cook the pasta",
                      text: "Salt and boil 2 cups water on high heat, then add pasta and boil for 10 minutes",
                      formattedText: [
                        .ingredient(Ingredient(emoji: "🧂", text: "Salt")),
                        .plain(" and boil "),
                        .ingredient(Ingredient(emoji: "💧", text: "2 cips water")),
                        .plain(" on high heat, then add "),
                        .ingredient(Ingredient(emoji: "🍝", text: "pasta", missingInfo: "10oz")),
                        .plain(" and "),
                        .timer(CookTimer(asText: "boil for 10 minutes", seconds: 10 * 60)),
                        .plain(".")
                      ]),
                .init(title: "Make the sauce",
                      text: "Stir in butter and half the scallions.",
                      formattedText: [
                        .plain("Stir in "),
                        .ingredient(Ingredient(emoji: "🧈", text: "butter", missingInfo: "2oz")),
                        .plain(" and "),
                        .ingredient(Ingredient(emoji: "🌱", text: "half the scallions", missingInfo: "1, finely chopped")),
                        .plain("."),
                      ]),
                .init(title: "Garnish and serve",
                      text: "Garnish with the remaining scallions and serve.",
                      formattedText: [
                        .plain("Garnish with the "),
                        .ingredient(Ingredient(emoji: "🌱", text: "remaining scallions", missingInfo: "1, finely chopped")),
                        .plain(" and serve."),
                      ]),
                .init(title: "Don't forget to sing the Pasta Song!",
                      text: "Single along with me: 'i love the pasta, i love the sauce, and afterward i love to floss'.",
                      formattedText: [
                        .plain("Single along with me: 'i love the pasta, i love the sauce, and afterward i love to floss'."),
                      ]),
            ],
            ingredients: [
                .init(emoji: "🍝", text: "8oz pasta"),
                .init(emoji: "🧈", text: "2oz butter"),
                .init(emoji: "🌱", text: "2 scallions, finely chopped")
            ]))
}
