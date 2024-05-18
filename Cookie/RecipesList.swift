import SwiftUI

struct RecipesList: View {
    @State private var selectedRecipeId: String?
    @State private var recipes = [String: Recipe]()

    var body: some View {
        let orderedRecipes = recipes.values.sorted(by: { $0.sortDate > $1.sortDate })
        List(orderedRecipes, selection: $selectedRecipeId) { recipe in
            RecipeCell(recipe: recipe)
                .swipeActions {
                    Button(role: .destructive, action: { AppStore.shared.model.recipes.removeValue(forKey: recipe.id) }) {
                        Image(systemName: "trash.fill")
                            .accessibilityLabel("Delete Recipe")
                    }
                }
        }
        .overlay {
            TimerOverlay()
        }
        .onReceive(AppStore.shared.publisher.map(\.recipes)) { self.recipes = $0 }
        .navigationTitle("Recipes")
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
}

struct RecipeCell: View {
    var recipe: Recipe

    var body: some View {
        HStack(spacing: 16) {
            image
                .frame(width: 80, height: 80)

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
                    content: { $0.resizable().interpolation(.high).aspectRatio(contentMode: .fill) },
                    placeholder: { Image(systemName: "fork.knife").font(.system(size: 30)).foregroundStyle(.tertiary) }
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 1)
    }
}

#Preview {
    NavigationStack {
        RecipesList()
    }
}
