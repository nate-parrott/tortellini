import Fuzi
import ChatToys
import Foundation

extension AppStore {
    func addRecipe(fromURL url: URL, html: String?, id: String) async throws {
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

        // Assemble context we'll send to the LLM
        var context = [String]()
        for jsonLD in htmlProcessor.doc.jsonLDElements {
            if let jsonLDRecipe = extractRecipeFromJSONLD(root: jsonLD) {
                context.append(jsonLDRecipe.asStringForLLM)
            }
        }
        context.append(htmlProcessor.markdown(urlMode: .omit, moveJsonLDToFront: false))
        let contextText = context.joined(separator: "\n\n").truncate(toTokens: 5000)
        print("[Add] Markdown:\n\(contextText.truncate(toTokens: 500))")

        guard let title = htmlProcessor.title?.nilIfEmpty else {
            throw AddRecipeError.noTitle
        }
        var recipe = Recipe(
            id: id,
            url: url,
            added: Date(),
            title: title,
            text: contextText,
            image: htmlProcessor.ogImage,
            parsed: nil,
            movedToFront: nil,
            generating: true
        )

        // Display partial recipe

        func updateAndYieldRecipe(_ block: (inout Recipe) -> Void) async {
            block(&recipe)
            await AppStore.shared.modifyAsync { $0.recipes[recipe.id] = recipe }
        }

        await updateAndYieldRecipe { _ in () }

        for try await partial in try await recipe.parseIntoBasicSteps() {
            await updateAndYieldRecipe { $0.parsed = partial }
        }

        print("[Add] Parsed:\n\(recipe.parsed!)")

        for try await parsedAndFormatted in try await recipe.parsed!.formatSteps() {
            await updateAndYieldRecipe { $0.parsed = parsedAndFormatted }
        }

        await updateAndYieldRecipe { $0.generating = nil }
//        let steps = try await recipe.parsed!.formatSteps()
//        recipe.parsed?.steps = steps
//        await AppStore.shared.modifyAsync { state in
//            state.recipes[recipe.id] = recipe
//        }
    }
}

