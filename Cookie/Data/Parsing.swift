import Fuzi
import Foundation
import ChatToys

extension Recipe {
    func parseIntoBasicSteps() async throws -> ParsedRecipe {
        enum Errors: Error {
            case noRecipePresent
        }

        let system = """
        Your job is to extract a recipe from a webpage and translate it into a specific JSON format.
        
        I'll give you a recipe, scraped from a webpage.

        You'll translate the recipe into JSON according to my schema, without changing any details of the recipe.
        """
        let body = """
        <recipe title='\(title)'>
        \(text.truncate(toTokens: 4000))
        </recipe>

        OK, that was the recipe webpage. Now, translate it
        into a valid JSON `Recipe` object, according to this exact Typescript schema:
        ```
        interface Recipe {
            recipePresent: Bool // Does a recipe exist in the webpage? true or false
            title: string // Remove SEO cruft from original title if present
            ingredients: Ingredient[]
            steps: Step[]
            summary: string // Quick 10-word summary of the cooking process, like "Cook pasta, roast chicken and serve with sauce."
        }

        interface Ingredient {
            text: string // e.g. "1.5 tsp cumin" or "1 cup chopped brocolli or bok choy"
            emoji: string // choose the closest FOOD or DRINK emoji
        }

        interface Step {
            text: string // the text of the step. Do not change this from how it appears on the page, other than cleaning up formatting.
            title: string // a descriptive 2-4 word title, like "Braise the Beef" or "Cook the Couscous". Avoid titles like "Step 1" -- write a more descriptive title instead. Each step's title should be unique; no repeats.
        }
        ```

        Your `Recipe` object below, and no other commentary, in a ```code block```:
        """

        let responsePrefix = "```\n{\n\t\"recipePresent\":"

        let messages: [LLMMessage] = [
            LLMMessage(role: .system, content: system),
            LLMMessage(role: .user, content: body)
        ]

        struct Output: Codable {
            var recipePresent: Bool
            var title: String?
            var ingredients: [Ingredient]
            var steps: [Step]
            var summary: String?
        }

//        let output = try await ClaudeNewAPI(credentials: .getSharedCredsOrThrow(), options: .init(model: .claude3Haiku, maxTokens: 4000, responsePrefix: responsePrefix))
        let output = try await ChatGPT(credentials: .getSharedOpenRouterCredsOrThrow(), options: .init(model: .custom("meta-llama/llama-3-70b-instruct:nitro", 8192), maxTokens: 8000, baseURL: .openRouterOpenAIChatEndpoint))
            .completeJSONObject(prompt: messages, type: Output.self)

        guard output.recipePresent else {
            throw Errors.noRecipePresent
        }

        return ParsedRecipe(
            title: output.title ?? title,
            description: output.summary,
            steps: output.steps,
            ingredients: output.ingredients
        )
    }
}

extension ParsedRecipe {
    func formatSteps() async throws -> [Step] {
        let system = """
        I'm making an app that formats recipes to make them easier to read and follow.

        I'd like to display ingredients in a special UI with emoji icons, and always displays quantities when ingredients are mentioned.

        I'd like to turn mentions of time ("cook for 10 minutes") into clickable buttons.

        I'll give you a recipe. Your job is to rewrite each step's text using a special XML syntax. When you see certain types of phrases, like references to an ingredient, or references to a cooking time, replace your text with a special XML annotation. These annotations will be formatted nicely to be more readable.

        Here are the very important rules for rewriting each step:
        - Wrap each step in <step> tags. Keep the number of steps the same as in the input.
        - Wrap mentions of ingredient in <ingredient> tags. If the INGREDIENTS LIST mentions an amount or preparation (e.g. finely chopped), but it's not mentioned in the step, add a `missing-details` attribute to fill it in. It should be possible to read the new recipe without referring back to the ingredients list for amounts and other details. If the recipe say something like "the remaining scallions" or "half the butter," do the math and put the appropriate amount in `missing-details.
        - Wrap each mention of a cook timer in a <timer> tag, so the user can tap to set a timer. If the recipe calls for repeating an action multiple times (e.g. "cook 7 minutes each side") set `repeat` appropriately, otherwise keep it at  1.
        - Besides these rules, keep the text and meaning of each step the same.
        - When wrapping things in <ingredient> or <timer>, do not change the inner text. Wrap in tags, don't rewrite.

        Ingredients tags look like this: <ingredient emoji="🧈" missing-details="10 oz">butter or ghee</ingredient>.
        Timer tags look like this: <timer hours={0} minutes={6} repeat={1} name>cook 6 minutes each side until crispy</timer>. // use repeat={2} when the recipe says to cook something N minutes per side.
        Steps tags look like this: <step index={N}> // one-indexed

        Here are some examples:

        # EXAMPLE
        Ingredients: 8oz pasta, 2oz butter, pinch of salt, 2 scallions (finely chopped).
        Steps:
        1. Salt and boil 2 cups water on high heat, then add pasta and boil for 10 minutes.
        2. Stir in butter and half the scallions.
        3. Garnish with remaining scallions and serve.

        Your output:
        ```
        <step index={1}>
        <ingredient emoji="🧂">Salt</ingredient> and boil <ingredient emoji="💧">2 cups water</ingredient> on high heat, then add <ingredient emoji="🍝" missing-details="10oz">pasta</ingredient> and <timer hours={0} minutes={10} repeat={1}>boil for 10 minutes</timer>.
        </step>
        <step index={2}>
        Stir in <ingredient emoji="🧈" missing-details="2oz">butter</ingredient> and <ingredient emoji="🌱" missing-details="1, finely chopped">half the scallions.</ingredient>.
        </step>
        <step index={3}>
        Garnish with the <ingredient emoji="🌱" missing-details="1, finely chopped">remaining scallions</ingredient> and serve.
        </step>
        ```
        """

        let user = """
        Below, here's the real recipe:
        [BEGIN RECIPE]
        Ingredients:
        \(ingredients.map{ "- " + $0.text }.joined(separator: "\n"))
        Steps:
        \(steps.enumerated().map({ (i, step) in
        return "\(i + 1). \(step.text)"
        }).joined(separator: "\n"))

        [END RECIPE]

        Now, rewrite this recipe's steps as a series of <step> tags within a ```code block```, using valid XML following the rules exactly:
        """

        let responsePrefix = "```\n<step index=\"1\">"
        let messages: [LLMMessage] = [
            LLMMessage(role: .system, content: system),
            LLMMessage(role: .user, content: user)
        ]
//        let llm = try ClaudeNewAPI(credentials: .getSharedCredsOrThrow(), options: .init(model: .claude3Haiku, maxTokens: 4000, responsePrefix: responsePrefix))
        let llm = try ChatGPT(credentials: .getSharedOpenRouterCredsOrThrow(), options: .init(model: .custom("meta-llama/llama-3-70b-instruct:nitro", 8192), maxTokens: 8000, baseURL: .openRouterOpenAIChatEndpoint))

        let response = try await llm.complete(prompt: messages).content.byExtractingOnlyCodeBlocks.withoutPrefix("xml")
        print("[Add] XML:\n\(response)")
        // Use HTML parsing b/c it's more lenient
        let parsed = try HTMLDocument(string: response, encoding: .utf8)

        var finalSteps = [Step]()
        for (unparsedStep, stepNode) in zip(steps, parsed.css("step")) {
            var step = unparsedStep
            step.formattedText = []
            for node in stepNode.childNodes(ofTypes: [.Text, .Element]) {
                switch node.type {
                case .Text:
                    step.formattedText!.append(.plain(node.stringValue.trimmingCharacters(in: .newlines)))
                case .Element:
                    if let el = node as? XMLElement, let item = Step.FormattedText.itemFromElement(el) {
                        step.formattedText!.append(item)
                    }
                default: ()
                }
            }
            finalSteps.append(step)
        }
        return finalSteps
    }
}

private extension Step.FormattedText {
    static func itemFromElement(_ element: XMLElement) -> Step.FormattedText? {
        guard let tag = element.tag else { return nil }
        switch tag.lowercased() {
        case "ingredient":
            guard let emoji = element.attr("emoji") else {
                return nil
            }
            let text = element.stringValue.trimmingCharacters(in: .newlines)
            let missingInfo = element.attr("missing-details")
            return .ingredient(Ingredient(emoji: emoji, text: text, missingInfo: missingInfo))

        case "timer":
            let hours = element.attr("hours")?.parsedAsInt ?? 0
            let minutes = element.attr("minutes")?.parsedAsInt ?? 0
            let seconds = hours * 3600 + minutes * 60
            let repeats = element.attr("repeat")?.parsedAsInt
            return .timer(CookTimer(
                asText: element.stringValue.trimmingCharacters(in: .newlines),
                seconds: seconds, 
                repeats: repeats)
            )

        default:
            return .plain(element.stringValue)

        }
    }
}

extension String {
    var parsedAsInt: Int? {
        Int(self)
    }
}

/*
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

 */
