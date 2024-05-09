import ChatToys
import Foundation

extension AppStore {
    func addRecipe(fromURL url: URL, id: String, html: String? = nil) async throws {
        enum AddRecipeError: Error {
            case notImplemented
            case noTitle
        }

        let htmlData: Data
        if let html {
            htmlData = html.data(using: .utf8) ?? Data()
        } else {
            htmlData = try await URLSession.shared.data(from: url).0
        }

        let htmlProcessor = try FastHTMLProcessor(url: url, data: htmlData)
        let markdown = htmlProcessor.markdown(urlMode: .omit)
        print("[Add] Markdown:\n\(markdown.truncate(toTokens: 500))")
        guard let title = htmlProcessor.title?.nilIfEmpty else {
            throw AddRecipeError.noTitle
        }
        var recipe = Recipe(
            id: id,
            url: url,
            added: Date(),
            title: title,
            text: markdown,
            image: htmlProcessor.ogImage,
            parsed: nil,
            movedToFront: nil
        )
        recipe.parsed = try await recipe.parseIntoBasicSteps()
        print("[Add] Parsed:\n\(recipe.parsed!)")
        let steps = try await recipe.parsed!.formatSteps()
        recipe.parsed?.steps = steps
        await AppStore.shared.modifyAsync { state in
            state.recipes[recipe.id] = recipe
        }
    }
}
