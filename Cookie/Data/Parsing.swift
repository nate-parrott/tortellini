import Fuzi
import Foundation
import ChatToys

extension Recipe {
    func parseIntoBasicSteps() async throws -> AsyncThrowingStream<ParsedRecipe, Error> {
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
            summary: string // Write a quick 10-word summary of the cooking process, like "Cook pasta, roast chicken and serve with sauce."
            yield: string? // e.g. "4 servings" or "1 loaf". Only include if mentioned in recipe data.
            prepTime: string? // e.g. "10 minutes" or "1 hour". Only include if mentioned in recipe data. Write in plain english.
            cookTime: string? // e.g. "30 minutes" or "2 hours" Only include if mentioned in recipe data. Write in plain english.
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

        Here are some good food-related emoji you might use for the `Ingredient.emoji` field (you can also use others):
        🧅🍏🍍🍇🥥🫛🌽🫑🥩🧀🥔🥚🌶️🍅🧂🧈🐟🍤🥬

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
            var ingredients: [Ingredient]?
            var steps: [Step]?
            var summary: String?
            var yield: String?
            var prepTime: String?
            var cookTime: String?
        }

//        let output = try await ClaudeNewAPI(credentials: .getSharedCredsOrThrow(), options: .init(model: .claude3Haiku, maxTokens: 4000, responsePrefix: responsePrefix))
        let llm = try ChatGPT(credentials: .getSharedOpenRouterCredsOrThrow(), options: .init(model: .custom("meta-llama/llama-3-70b-instruct:nitro", 8192), maxTokens: 8000, baseURL: .openRouterOpenAIChatEndpoint))
        return llm.completeStreamingWithJSONObject(prompt: messages, type: Output.self, completeLinesOnly: true).mapSimple { output in
            ParsedRecipe(
                title: output.title ?? title,
                description: output.summary,
                steps: output.steps ?? [],
                ingredients: output.ingredients ?? [],
                yield: output.yield,
                cookTime: output.cookTime,
                prepTime: output.prepTime
            )
        }
    }
}

extension ParsedRecipe {
    func formatSteps() async throws -> AsyncThrowingStream<ParsedRecipe, Error> {
        enum Errors: Error {
            case invalidXML
        }

        let system = """
        I'm making an app that formats recipes to make them easier to read and follow.

        I'd like to display ingredients in a special UI with emoji icons, and always displays quantities when ingredients are mentioned.

        I'd like to turn mentions of time ("cook for 10 minutes") into clickable buttons.

        I'll give you a recipe. Your job is to rewrite each step's text using a special XML syntax. When you see certain types of phrases, like references to an ingredient, or references to a cooking time, replace your text with a special XML annotation. These annotations will be formatted nicely to be more readable, and contain valuable information.

        Here are the very important rules for rewriting each step:

        Rule: Wrap each step in <step> tags. Keep the number of steps the same as in the input.

        Rule: Wrap mentions of ingredients in <ingredient> tags.
        Each <ingredient> tag should have a `details` attribute that tells you the amount of ingredient, and the preparation (diced, chopped, toasted, etc), if it's known from the ingredients list. For example, if the step says "Add the cilantro", and the ingredients list calls for "1 cup cilanto, finely chopped", the you'd write "1 cup, finely chopped" in the details field.

        Rule: Wrap each mention of a cook timer in a <timer> tag, so the user can tap to set a timer.
        If the recipe calls for repeating an action multiple times (e.g. "cook 7 minutes each side") set `repeat` appropriately, otherwise keep it at  1.

        Rule: Besides these rules, keep the text and meaning of each step the same.

        Rule: When wrapping things in <ingredient> or <timer>, do not change the inner text. Wrap in tags, don't rewrite.

        Ingredients tags look like this: <ingredient emoji="🧈" details="10 oz">butter or ghee</ingredient>. Choose a related FOOD or DRINK emoji.

        Timer tags look like this: <timer hours={0} minutes={6} repeat={1} name>cook 6 minutes each side until crispy</timer>.
        Always fill in the hours and minutes. If the timer is a range, like 5-6 minutes, give the low end.
        Use repeat={2} when the recipe says to cook something N minutes per side.

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
        <ingredient emoji="🧂">Salt</ingredient> and boil <ingredient emoji="💧">2 cups water</ingredient> on high heat, then add <ingredient emoji="🍝" details="10oz">pasta</ingredient> and <timer hours={0} minutes={10} repeat={1}>boil for 10 minutes</timer>.
        </step>
        <step index={2}>
        Stir in <ingredient emoji="🧈" details="2oz">butter</ingredient> and <ingredient emoji="🌱" details="1, finely chopped">half the scallions.</ingredient>.
        </step>
        <step index={3}>
        Garnish with the <ingredient emoji="🌱" details="1, finely chopped">remaining scallions</ingredient> and serve.
        </step>
        ```
        """

        let user = """
        Below, here's the real recipe:
        [BEGIN RECIPE]
        \(forLLM)
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
//        let response = try await llm.complete(prompt: messages).content.byExtractingOnlyCodeBlocks.withoutPrefix("xml")

        return AsyncThrowingStream<ParsedRecipe, Error> { cont in
            Task {
                do {
                    var lastXML: String?
                    var lines = [String]()
                    for try await line in llm.completeStreamingLineByLine(prompt: messages) {
                        lines.append(line)
                        let xml = lines.joined(separator: "\n").byExtractingOnlyCodeBlocks.withoutPrefix("xml")
                        if let parsed = try? self.applyingFormattedStepsXML(xml: xml) {
                            cont.yield(parsed)
                        }
                        lastXML = xml
                    }
                    guard let lastXML else {
                        throw Errors.invalidXML
                    }
                    print("XML:\n\(lastXML)")
                    let parsed = try applyingFormattedStepsXML(xml: lastXML)
                    cont.yield(parsed)
                    cont.finish()
                } catch {
                    cont.finish(throwing: error)
                }
            }
        }
    }
}

extension ParsedRecipe {
    func applyingFormattedStepsXML(xml: String) throws -> ParsedRecipe {
//        print("[Add] XML:\n\(xml)")
        // Use HTML parsing b/c it's more lenient
        let parsed = try HTMLDocument(string: xml, encoding: .utf8)

        var steps = self.steps
        for (i, stepNode) in parsed.css("step").enumerated() {
            guard i < steps.count else { continue }
            var step = steps[i]
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
            steps[i] = step
        }

        var output = self
        output.steps = steps
        return output
    }

    var forLLM: String {
        return """
        Title: \(title)
        Ingredients:
        \(ingredients.map{ "- " + $0.emoji + " " + $0.text }.joined(separator: "\n"))
        Steps:
        \(steps.enumerated().map({ (i, step) in
        return "\(i + 1). \(step.text)"
        }).joined(separator: "\n"))
        """
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
            let missingInfo = element.attr("details")
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
