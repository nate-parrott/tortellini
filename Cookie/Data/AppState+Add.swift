import Fuzi
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

        // Assemble context we'll send to the LLM
        var context = [String]()
        if let jsonLD = htmlProcessor.doc.jsonLD, let (steps, ingredients) = extractRecipeFromJSONLD(root: jsonLD) {
            let asStr = """
            INGREDIENTS:
            \(ingredients.joined(separator: "- "))
            STEPS:
            \(steps.joined(separator: "- "))
            """
            context.append(asStr)
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

extension HTMLDocument {
    var jsonLD: Any? {
        if let text = css("script[type='application/ld+json']").first?.stringValue.nilIfEmpty {
            return try? JSONSerialization.jsonObject(with: text.data(using: .utf8)!)
        }
        return nil
    }
}

func extractRecipeFromJSONLD(root: Any) -> (steps: [String], ingredients: [String])? {
    var steps = [String]()
    var ingredients = [String]()

    func visit(node: Any) {
        // Visit children
        if let dict = node as? [String: Any] {
            for val in dict.values {
                visit(node: val)
            }
        }
        if let arr = node as? [Any] {
            for val in arr {
                visit(node: val)
            }
        }

        // Look for data at this node
        guard let dict = node as? [String: Any], let type = dict["@type"] else { return }
        let types: [String]
        if let typeStr = type as? String {
            types = [typeStr]
        } else if let typeArr = type as? [String] {
            types = typeArr
        } else {
            return
        }
        if types.contains("Recipe") {
            if let ing = dict["recipeIngredient"] as? [String] {
                ingredients += ing
            }
        }
        if types.contains("HowToStep"), let text = dict["text"] as? String {
            steps.append(text)
        }
    }

    visit(node: root)

    if steps.count > 0 || ingredients.count > 0 {
        return (steps, ingredients)
    }
    return nil
}
