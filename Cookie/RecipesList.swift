import SwiftUI

struct RecipesList: View {
    @State private var selectedRecipeId: String?
    @State private var recipes = [String: Recipe]()
    @State private var addInProgress = false
    @State private var error: String?

    var body: some View {
        let orderedRecipes = recipes.values.sorted(by: { $0.sortDate > $1.sortDate })
        List(orderedRecipes, selection: $selectedRecipeId) { recipe in
            RecipeCell(recipe: recipe)
                .swipeActions {
                    Button(action: { AppStore.shared.model.recipes.removeValue(forKey: recipe.id) }, label: {
                        Image(systemName: "trash.fill")
                            .accessibilityLabel("Remove Recipe")
                    })
                }
        }
        .onReceive(AppStore.shared.publisher.map(\.recipes)) { self.recipes = $0 }
        .navigationTitle("Recipes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: addViaURL) {
                    if addInProgress {
                        ProgressView()
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .accessibilityLabel("Add Recipe")
                    }
                }
            }
        }
        .alert("Oops, I couldn't add that recipe.", isPresented: errBinding) {
            Button(action: { errBinding.wrappedValue = false }, label: {
                Text("Okat")
            })
        }
        .sheet(item: showingRecipeBinding) { recipe in
            if let parsed = recipe.parsed {
                RecipeView(recipe: recipe, parsed: parsed)
            } else {
                ProgressView()
                    .frame(minWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var showingRecipeBinding: Binding<Recipe?> {
        .init(get: {
            if let selectedRecipeId {
                return recipes[selectedRecipeId]
            }
            return nil
        }) { recipeOpt in
            selectedRecipeId = recipeOpt?.id
        }
    }

    private var errBinding: Binding<Bool> {
        .init(get: { error != nil }, set: { newVal in if !newVal { error = nil } })
    }

    private func addViaURL() {
        Task {
            self.addInProgress = true
            defer {
                self.addInProgress = false
            }
            self.error = nil
            guard let text = await UIApplication.shared.prompt(title: "Add Recipe", message: "Paste a link:", placeholder: "https://meatballs.com/gravy"),
                  let url = URL(string: text)
            else {
                return
            }
            do {
                try await AppStore.shared.addRecipe(fromURL: url)
            } catch {
                print("Failed to add recipe: \(error)")
                self.error = "\(error)"
            }
        }
    }
}

struct RecipeCell: View {
    var recipe: Recipe

    var body: some View {
        HStack {
            image
                .frame(width: 80, height: 60)

            VStack(alignment: .leading) {
                Text(recipe.parsed?.title ?? recipe.title)
                    .font(.headline)

                if let url = recipe.url {
                    Text(url.hostWithoutWWW)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.leading)
            .lineLimit(3)
        }
        .padding(.leading, -10)
        .contextMenu {
            if let url = recipe.url {
                Button("Copy Link") {
                    UIPasteboard.general.url = url
                }
            }
            Button("Move to Top") {
                AppStore.shared.model.recipes[recipe.id]?.movedToFront = Date()
            }
            Button("Remove Recipe", role: .destructive) {
                AppStore.shared.model.recipes.removeValue(forKey: recipe.id)
            }
        }
    }

    @ViewBuilder private var image: some View {
        Rectangle().fill(.quinary.opacity(0.3))
            .overlay {
                AsyncImage(
                    url: recipe.image,
                    content: { $0.resizable().aspectRatio(contentMode: .fill) },
                    placeholder: { Image(systemName: "fork.knife").font(.system(size: 30)).foregroundStyle(.tertiary) }
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        RecipesList()
    }
}
