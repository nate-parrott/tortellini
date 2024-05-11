import SwiftUI

struct BrowserWithRecipeAdder: View {
    @State private var addRequest: AddRecipeRequest?

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        if let addRequest {
            RecipeAdder(addRequest: addRequest)
        } else {
            NavigationStack {
                Browser(onWantsToAddRecipe: { addRequest = $0 }, onDismiss: {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }
}
