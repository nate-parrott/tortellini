import SwiftUI

struct AddRecipeRequest: Equatable, Identifiable {
    var id: URL { url }
    var url: URL
    var html: String?
}

struct Browser: View {
    var onWantsToAddRecipe: ((AddRecipeRequest) -> Void)
    var onDismiss: () -> Void

    @StateObject private var webContent = WebContent()
    @State private var search = ""
    @State private var isSearching = false

    var body: some View {
        WebView(content: webContent)
            .navigationTitle(webContent.info.title ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $search,
                isPresented: $isSearching,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: webContent.info.url.map { Text($0.hostWithoutWWW) }
            )
            .disableAutocorrection(true)
            .onSubmit(of: .search) {
                if search != "" {
                    let url = URL.withSearchQuery(search)
                    search = ""
                    webContent.load(url: url)
                    isSearching = false
//                    dismissSearch()
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button(action: { onDismiss() }) {
                        Text("Close")
                    }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: add) {
                        Text("Add Recipe")
                            .bold()
                    }
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: { webContent.goBack() }) {
                        Image(systemName: "chevron.backward")
                            .accessibilityLabel(Text("Navigate back"))
                    }
                    .disabled(!webContent.info.canGoBack)

                    Button(action: { webContent.goForward() }) {
                        Image(systemName: "chevron.forward")
                            .accessibilityLabel(Text("Navigate forward"))
                    }
                    .disabled(!webContent.info.canGoForward)

                    Spacer()
                }
            }
            .onAppear {
                if webContent.info.url == nil {
                    webContent.load(url: URL(string: "https://google.com")!)
                }
            }
    }

    private func add() {
        Task {
            let html = try? await webContent.evaluateJavascript("document.documentElement.outerHTML") as? String
            guard let url = webContent.info.url else { return }
            DispatchQueue.main.async {
                onWantsToAddRecipe(AddRecipeRequest(url: url, html: html))
            }
        }
    }
}

#Preview {
    NavigationStack {
        Browser(onWantsToAddRecipe: {_ in () }, onDismiss: {})
    }
}
