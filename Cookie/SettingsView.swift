import SwiftUI

enum DefaultsKeys: String {
    case anthropicApiKey
}

struct SettingsView: View {
    @AppStorage(DefaultsKeys.anthropicApiKey.rawValue) var apiKey: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Anthropic API Key")) {
                TextField("API Key", text: $apiKey)
            }
        }
        .navigationTitle("Settings")
    }
}
