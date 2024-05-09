import AVFoundation
import SwiftUI
import ChatToys
import Foundation

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
    var lastSpokenResponseDate: Date? // When did the system finish speaking its last response
    var listeningTask: Task<Void, Never>?
    var debugStatus: String? {
        didSet {
            print("[VoiceAssistant]: \(debugStatus)")
        }
    }
    let speechPauseBeforeAnswering: TimeInterval = 0.8

    var listening = false {
        didSet {
            if listening != oldValue {

                if listening {
//                    try! AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
//                    try! AVAudioSession.sharedInstance().setAllowHapticsAndSystemSoundsDuringRecording(true)
//                    try! AVAudioSession.sharedInstance().setActive(true, options: [])

                    listeningTask = Task {
                        await listenLoop()
                    }
                } else {
                    listeningTask?.cancel()
                    listeningTask = nil
                    try? AVAudioSession.sharedInstance().setActive(false, options: [])
                }
            }
        }
    }

    deinit {
        try? AVAudioSession.sharedInstance().setActive(false, options: [])
//        listeningTask?.cancel()
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
                let resp = try await getLLM().complete(prompt: constructLLMMessages())
                // TOOD: Handle functions
                messages.append(.answer(resp.content.trimmingCharacters(in: .whitespacesAndNewlines)))
                break
            } catch {
                messages.append(.error("\(error)"))
                break
            }
        }
        typing = false
    }

    private func listenLoop() async {
        if Task.isCancelled { return }

        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord)
//        let gen = AppleSpeechGenerator(managesAudioSession: false)
//        await gen.speak("Hi it's Tommy. I'm listening.")
//        await gen.awaitFinishedSpeaking()

        try? await Task.sleep(seconds: 1)

        if Task.isCancelled { return }

        debugStatus = "Listening"
        let rec = SpeechRecognizer()
        await rec.start()

        var state = rec.status

        var allowSpeechWithoutWake = false

        singleAnswerLoop:
        while true {
            debugStatus = "State: \(state)"

            switch state {
            case .errored:
                debugStatus = "Error"
                rec.cancel()
                self.listening = false
                return
            case .starting:
                debugStatus = "Starting"
            case .finalizedText, .none: () // not expected; we don't finalize text
            case .recognizedText(let text):
                if let lastSpokenResponseDate, lastSpokenResponseDate.isWithinPast(seconds: 10), text.nilIfEmptyOrJustWhitespace != nil {
                    allowSpeechWithoutWake = true
                    debugStatus = "Allowing speech without wake due to response"
                }

                let postWakeText: String? = {
                    if let postWakeText = text.textAfterWakeWord {
                        return postWakeText
                    }
                    if allowSpeechWithoutWake {
                        return text.nilIfEmptyOrJustWhitespace
                    }
                    return nil
                }()

                if let lastUpdate = rec.lastTextUpdateDate, let postWakeText {
                    let elapsed = Date.now.timeIntervalSinceReferenceDate - lastUpdate.timeIntervalSinceReferenceDate
                    let delay = max(0, speechPauseBeforeAnswering - elapsed)
                    debugStatus = "Text: \(text); Pausing for \(delay)"
                    try? await Task.sleep(seconds: delay)
                    if rec.status == state {
                        // If still unchanged, the user has paused. Handle it!
                        debugStatus = "Pause done; time to send \(postWakeText) to llm"
                        do {
                            let promptMessages = await constructLLMMessages() + [LLMMessage(role: .user, content: postWakeText)]
                            let response = try await getLLM().complete(prompt: promptMessages).content.trimmingCharacters(in: .whitespacesAndNewlines)

                            if rec.status == state {
                                debugStatus = "Success!"
                                messages.append(.user(postWakeText))
                                messages.append(.answer(response))
                                rec.cancel()
                                let gen = AppleSpeechGenerator()
                                await gen.speak(response)
                                await gen.awaitFinishedSpeaking()
                                self.lastSpokenResponseDate = Date()
                                // TODO: Handle tools
                                break singleAnswerLoop
                            } else {
                                debugStatus = "LLM responded but text changed"
                            }
                        } catch {
                            debugStatus = "LLM error: \(error)"
                            rec.cancel()
                            self.listening = false
                            return
                        }
                    } else {
                        debugStatus = "Text changed during pause"
                    }
                } else {
                    debugStatus = "No trigger for dictation \(text)"
                }
            }

            debugStatus = "Waiting for next status change"
            if let next = await rec.awaitChange(fromStatus: state) {
                state = next
            } else {
                break singleAnswerLoop
            }
        }
        rec.stop()
        debugStatus = "Done, going again"

        // Start new recording
        try? await Task.sleep(seconds: 0.2)
        await listenLoop()
    }

    private func getLLM() throws -> any ChatLLM {
        try ChatGPT(credentials: .getSharedOpenRouterCredsOrThrow(), options: .init(model: .custom("meta-llama/llama-3-70b-instruct:nitro", 8192), maxTokens: nil, baseURL: .openRouterOpenAIChatEndpoint))
    }
}

extension String {
    var textAfterWakeWord: String? {
        let wakeWords = ["Hi Tommy", "Hey Tommy", "Hi Chef", "Hey Chef"]
        // Search case insensitive for this phrase
        for word in wakeWords {
            if let range = self.range(of: word, options: .caseInsensitive) {
                return self[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmptyOrJustWhitespace
            }
        }
        return nil
    }
}

extension SpeechRecognizer {
    func awaitChange(fromStatus: Status) async -> Status? {
        for await state in $status.values {
            if state != fromStatus {
                return state
            }
        }
        return nil
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
    var assistant: VoiceAssistant

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

            Text(assistant.debugStatus ?? "...")
                .padding()
                .foregroundStyle(.white)
                .background(.red)
                .lineLimit(nil)
        }
//        .onAppear {
//            assistant.listening = true
//        }
//        .onDisappear {
//            assistant.listening = false
//        }
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
