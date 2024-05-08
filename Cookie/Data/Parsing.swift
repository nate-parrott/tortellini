import Foundation

extension Recipe {
    func parseIntoBasicSteps() async throws -> (summary: String?, steps: [Step]) {
        let system = """
        Your job is to extract a recipe from a webpage and translate it into a specific JSON format.
        
        I'll give you a recipe, scraped from a webpage.

        You'll translate the recipe into JSON according to my schema, without changing any details of the recipe.
        """
        let body = """
        <recipe title='\(title)'>
        \(text)
        </recipe>

        OK, that was the recipe webpage. Now, translate it
        into valid JSON, according to this exact Typescript schema:
        ```
        interface Recipe {
            recipePresent: Bool // Does a recipe exist in the webpage? true or false
            title: string // Remove SEO cruft from original title if present
            description: string // 1-2 sentence description of the dish. If you find this on the page, great; otherwise write one.
            ingredients: Ingredient[]
            steps: Step[]
        }

        interface Ingredient {
            text: string // e.g. "1.5 tsp cumin" or "1 cup chopped brocolli or bok choy"
            emoji: string // closest related emoji
        }

        interface Step {
            text: string // the text of the step. Do not change this from how it appears on the page, other than cleaning up formatting.
            title: string // a descriptive 2-4 word title, like "Braise the Beef" or "Cook the Couscous". Avoid titles like "Step 1" -- write a more descriptive title instead. Each step's title should be unique; no repeats.
        }
        ```
        """

        struct Output: Codable {
            var recipePresent: Bool
            var title: String?
            var description: String?
            var ingredients: [Ingredient]?
            var steps: [Step]?
        }
        fatalError()
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
        - Wrap each step in <step> tags. Keep the number of steps the same.
        - Wrap each mention of an ingredient in <ingredient> tags. If the INGREDIENTS LIST mentions an amount or preparation (e.g. finely chopped), but it's not mentioned in the step, add a `missing-details` attribute to fill it in. It should be possible to read the new recipe without referring back to the ingredients list for amounts and other details. If the recipe say something like "the remaining scallions" or "half the butter," do the math.
        - Wrap each mention of a cook timer in a <timer> tag, so the user can tap to set a timer.
        - Besides these rules, keep the text and meaning of each step the same.

        Ingredients tags look like this: <ingredient emoji="🧈" missing-details="10 oz">butter or ghee</ingredient>.
        Timer tags look like this: <timer hours={0} minutes={6} repeat={2} name>cook 6 minutes each side until crispy</timer>.
        Steps tags look like this: <step index={N}> // one-indexed

        Here are some examples:

        # EXAMPLE
        Ingredients: 8oz pasta, 2oz butter, pinch of salt, 2 scallions (finely chopped).
        Steps:
        1. Salt and boil 2 cups water on high heat, then add pasta and boil for 10 minutes.
        2. Stir in butter and half the scallions.
        3. Garnish with remaining scallions and serve.

        Your output:
        <step index={1}>
        <ingredient emoji="🧂">Salt</ingredient> and boil <ingredient emoji="💧">2 cups water</ingredient> on high heat, then add <ingredient emoji="🍝" missing-details="10oz">pasta</ingredient> and <timer hours={0} minutes={10} repeat={1}>boil for 10 minutes</timer>.
        </step>
        <step index={2}>
        Stir in <ingredient emoji="🧈" missing-details="2oz">butter</ingredient> and <ingredient emoji="🌱" missing-details="1, finely chopped">half the scallions.</ingredient>.
        </step>
        <step index={3}>
        Garnish with the <ingredient emoji="🌱" missing-details="1, finely chopped">remaining scallions</ingredient> and serve.
        </step>
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

        Now, rewrite this recipe's steps using the precise rules and XML schema described above:
        """

        let responsePrefix = "<step index=\"1\">"
        fatalError()
    }
}
