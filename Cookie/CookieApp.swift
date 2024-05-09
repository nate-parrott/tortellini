//
//  CookieApp.swift
//  Cookie
//
//  Created by nate parrott on 5/8/24.
//

import SwiftUI

@main
struct CookieApp: App {
    var body: some Scene {
        WindowGroup {
            RecipesWindow()
        }
    }
}

struct RecipesWindow: View {
    @State private var adding: Addable?
    @State private var showSettings = false

    struct Addable: Identifiable {
        var id: URL { url }
        var url: URL
    }

    var body: some View {
        NavigationStack {
            RecipesList()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showSettings = true }) {
                            Image(systemName: "person.crop.circle")
                                .accessibilityLabel("Settings and Profile")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: addViaURL) {
                            Image(systemName: "plus.circle.fill")
                                .accessibilityLabel("Add Recipe")
                        }
                    }
                }
//                .navigationDestination(for: AppRoute.self) { route in
//                    ViewForRoute(route: route)
//                }
        }
        .sheet(item: $adding, content: { adding in
            RecipeAdder(url: adding.url)
                .id(adding.url)
        })
        .sheet(isPresented: $showSettings, content: {
            NavigationStack {
                SettingsView()
            }
        })
        .onOpenURL { url in
            UIApplication.shared.ensureModalsDismissed {
                self.adding = .init(url: url)
            }
        }
    }

    private func addViaURL() {
        Task {
            guard let text = await UIApplication.shared.prompt(title: "Add Recipe", message: "Paste a link:", placeholder: "https://meatballs.com/gravy"),
                  let url = URL(string: text)
            else {
                return
            }
            DispatchQueue.main.async {
                self.adding = .init(url: url)
            }
        }
    }

    private func handle(url: URL) {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return
        }
        switch parts.scheme ?? "" {
        case "save-cookie-recipe":
            if let urlStr = (parts.queryItems ?? []).filter({ $0.name == "url" }).first?.value, let parsed = URL(string: urlStr) {
                self.adding = .init(url: url)
            }
        default:
            print("Tried to open URL with unrecognized scheme: \(url)")
        }
    }
}
//
//enum AppRoute: Equatable {
//    case settings
//}
//
//struct ViewForRoute: View {
//    var route: AppRoute
//
//    var body: some View {
//        switch route {
//        case .settings:
//            SettingsView()
//        }
//    }
//}