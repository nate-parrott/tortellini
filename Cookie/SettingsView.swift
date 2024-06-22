import SwiftUI

enum DefaultsKeys: String {
    case anthropicApiKey
    case openAIApiKey
    case openRouterAPIKey
    case elevenLabsAPIKey
}

struct SettingsView: View {
    @AppStorage(DefaultsKeys.anthropicApiKey.rawValue) var anthropicKey: String = ""
    @AppStorage(DefaultsKeys.openAIApiKey.rawValue) var openAIKey: String = ""
    @AppStorage(DefaultsKeys.openRouterAPIKey.rawValue) var openRouterKey: String = ""
    @AppStorage(DefaultsKeys.elevenLabsAPIKey.rawValue) var elevenLabsAPIKey: String = ""

    var body: some View {
        Form {
//            Section(header: Text("Anthropic API Key")) {
//                TextField("API Key", text: $anthropicKey)
//            }
            Section(header: Text("OpenAI API Key")) {
                TextField("API Key", text: $openAIKey)
            }
//            Section(header: Text("OpenRouter API Key")) {
//                TextField("API Key", text: $openRouterKey)
//            }
//            Section(header: Text("ElevenLabs API Key")) {
//                TextField("API Key", text: $elevenLabsAPIKey)
//            }
        }
        .navigationTitle("Settings")
    }
}
