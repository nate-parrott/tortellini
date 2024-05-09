import SwiftUI
import ChatToys
import Foundation

/*
 struct Recipe: Equatable, Codable, Identifiable {
     var id: String
     var url: URL?
     var added: Date
     var title: String
     var text: String // e.g. markdown, or extracted data
     var image: URL?
     var parsed: ParsedRecipe?
     var movedToFront: Date?
     var generating: Bool?

     var sortDate: Date {
         movedToFront ?? added
     }
 }

 struct ParsedRecipe: Equatable, Codable {
     var title: String
     var description: String?
     var steps: [Step]
     var ingredients: [Ingredient]
 }

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

@MainActor
@Observable
class VoiceAssistant {
    nonisolated init() {}

    enum Message: Equatable {
        case user(String)

        case answer(String)

        case setTimerCall(String, Int)
        case removerTimerCall(String)
        case modifyTimerCall(String, Int)

        case timerEditResponse(functionName: String, newTimers: String)

        case error(String)

        var isFunctionResponse: Bool {
            switch self {
            case .timerEditResponse: return true
            case .user, .answer, .setTimerCall, .removerTimerCall, .modifyTimerCall, .error: return false
            }
        }

        func asLLMMessage() -> LLMMessage {
            switch self {
            case .user(let string):
                return LLMMessage(role: .user, content: string)
            case .answer(let string):
                return LLMMessage(role: .assistant, content: string)
            case .setTimerCall(let string, let int):
                fatalError()
            case .removerTimerCall(let string):
                fatalError()
            case .modifyTimerCall(let string, let int):
                fatalError()
            case .timerEditResponse(let functionName, let newTimers):
                fatalError()
            case .error(let string):
                return LLMMessage(role: .system, content: "Error: \(string)")
            }
        }
    }

    var messages = [Message]()
    var typing = false

    var on = false {
        didSet {
            if on != oldValue {
                // todo
            }
        }
    }

    private func constructLLMMessages() async -> [LLMMessage] {
        var out = [LLMMessage]()
        let state = await AppStore.shared.readAsync()
        out.append(LLMMessage(role: .system, content: state.voiceAssistantSystemMessage()))

        var truncatedMessages = messages.suffix(12)
        while let first = truncatedMessages.first, first.isFunctionResponse {
            truncatedMessages.removeFirst()
        }

        out += truncatedMessages.map { $0.asLLMMessage() }
        return out
    }

    func send(message: String) async {
        messages.append(.user(message))

        while true {
            do {
                let llm = try ChatGPT(credentials: .getSharedOpenRouterCredsOrThrow(), options: .init(model: .custom("meta-llama/llama-3-70b-instruct:nitro", 8192), maxTokens: nil, baseURL: .openRouterOpenAIChatEndpoint))
                let resp = try await llm.complete(prompt: constructLLMMessages())
                // TOOD: Handle functions
                messages.append(.answer(resp.content))
                break
            } catch {
                messages.append(.error("\(error)"))
                break
            }
        }
        typing = false
    }
}

extension AppState {
    func voiceAssistantSystemMessage() -> String {
        var lines = [String]()

        lines.append("""
        You are Tommy Tortellini, a master chef and cooking teacher who helps guide home cooks through cooking recipes.
        A user is cooking or reading a recipe. Your job is to provide QUICK, TERSE answers to their questions hands-free while they cook.

        For example, if a user asked 'how long do I cook the chicken?', you'd refer to the recipe and say something like "Cook the chicken 7 minutes per side on high heat."

        The user may have some cooking timers active, which you can answer questions about, like "how long left on the vegetables?"
        """)

        if let lastActiveRecipe, let parsed = recipes[lastActiveRecipe]?.parsed {
            lines.append("Current recipe:")
            lines.append("<recipe>")
            lines.append(parsed.forLLM)
            lines.append("</recipe>")
        }

        lines.append("Active timers:")
        lines.append("<timers>")
        for timer in timers {
            lines.append(" \(timer.asContextForLLM)")
        }
        lines.append("</timers>")

        // TODO: Add recently completed timers

        return lines.joined(separator: "\n")
    }
}

struct VoiceAssistantDebug: View {
    @State private var assistant = VoiceAssistant()

    @State private var text = ""

    var body: some View {
        VStack(spacing: 0) {
            ChatThreadView(messages: assistant.messages, id: { _, idx in idx }, messageView: { MessageView(message: $0) }, typingIndicator: assistant.typing)

            ChatInputView(placeholder: "Ask...", text: $text) {
                if let text = text.nilIfEmptyOrJustWhitespace {
                    Task {
                        await assistant.send(message: text)
                    }
                }
                text = ""
            }
        }
    }
}

// Use this:
//public struct TextMessageBubble: View {
//    public var text: Text
//    public var isFromUser: Bool


private struct MessageView: View {
    var message: VoiceAssistant.Message

    var body: some View {
        switch message {
        case .user(let string):
            TextMessageBubble(Text(string), isFromUser: true)
        case .answer(let string):
            TextMessageBubble(Text(string), isFromUser: false)
        case .setTimerCall(let string, let int):
            TextMessageBubble(Text("Set timer for \(string) for \(int) seconds"), isFromUser: false)
        case .removerTimerCall(let string):
            TextMessageBubble(Text("Remove timer for \(string)"), isFromUser: false)
        case .modifyTimerCall(let string, let int):
            TextMessageBubble(Text("Modify timer for \(string) to \(int) seconds"), isFromUser: false)
        case .timerEditResponse(let functionName, let newTimers):
            TextMessageBubble(Text("Edited timers"), isFromUser: false)
        case .error(let string):
            TextMessageBubble(Text("Error: \(string)"), isFromUser: false)
        }
    }
}
