import Foundation
import Fuzi

extension HTMLDocument {
    var jsonLDElements: [Any] {
        css("script[type='application/ld+json']").compactMap { el in
            if let text = el.stringValue.nilIfEmpty {
                return try? JSONSerialization.jsonObject(with: text.data(using: .utf8)!)
            }
            return nil
        }
    }
}

struct JsonLDRecipe {
    var steps: [String]
    var ingredients: [String]
    var yield: String?
    var cookTime: String?
    var prepTime: String?

    var isEmpty: Bool {
        steps.count == 0 && ingredients.count == 0
    }

    var asStringForLLM: String {
        var lines = [String]()
        if ingredients.count > 0 {
            lines.append("# INGREDIENTS")
            lines += ingredients.map { "- " + $0 }
        }
        if steps.count > 0 {
            lines.append("# STEPS")
            lines += steps.map { "- " + $0 }
        }
        if let yield = yield {
            lines.append("# YIELD")
            lines.append(yield)
        }
        if let cookTime = cookTime {
            lines.append("# COOK TIME (json LD format)")
            lines.append(cookTime)
        }
        if let prepTime = prepTime {
            lines.append("# PREP TIME (json LD format)")
            lines.append(prepTime)
        }
        return lines.joined(separator: "\n")
    }
}

func extractRecipeFromJSONLD(root: Any) -> JsonLDRecipe? {
    var ld = JsonLDRecipe(steps: [], ingredients: [])

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
                ld.ingredients += ing
            }
            if let instr = dict["recipeInstructions"] as? String {
                ld.ingredients.append(instr)
            }
            if let yield = dict["recipeYield"] as? String {
                ld.yield = yield
            }
            if let cookTime = dict["cookTime"] as? String {
                ld.cookTime = cookTime
            }
            if let prepTime = dict["prepTime"] as? String {
                ld.prepTime = prepTime
            }
        }
        if types.contains("HowToStep"), let text = dict["text"] as? String {
            ld.steps.append(text)
        }
    }

    visit(node: root)

    if ld.isEmpty {
        return nil
    }

    return ld
}
