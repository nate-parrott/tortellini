import SwiftUI

// Do not reuse for multiple urls
struct RecipeAdder: View {
    var addRequest: AddRecipeRequest

    @State private var id: String = "???"
    @State private var error: String?
    @State private var recipe: Recipe?

    var body: some View {
        ZStack {
            if let recipe, let parsed = recipe.parsed {
                RecipeView(recipe: recipe, parsed: parsed)
            } else if let error {
                Text("I couldn't add this recipe")
                    .font(.title2.bold())
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 20) {
                    ProgressView()

                    Text("Adding recipe...")
                        .font(.title2.bold())
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .lineLimit(nil)
        .multilineTextAlignment(.center)
        .fontDesign(.rounded)
        .onAppear {
            add()
        }
        .onReceive(AppStore.shared.publisher.map { $0.recipes[id] }) { self.recipe = $0 }
    }

    private func add() {
        let id = UUID().uuidString
        self.error = nil
        self.recipe = nil
        self.id = id

        Task {
            do {
                try await AppStore.shared.addRecipe(fromURL: addRequest.url, html: addRequest.html, id: id)
            } catch {
                self.error = "I couldn't add this recipe"
                print("Recipe add error: \(error)")
            }
        }
    }
}
