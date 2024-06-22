import Foundation
import ChatToys

extension AnthropicCredentials {
    static var shared: AnthropicCredentials? {
        if let key = UserDefaults.standard.string(forKey: DefaultsKeys.anthropicApiKey.rawValue)?.nilIfEmpty {
            return .init(apiKey: key)
        }
        return nil
    }

    static func getSharedCredsOrThrow() throws -> AnthropicCredentials {
        enum Errors: Error {
            case noAnthropicKey
        }
        guard let shared else {
            throw Errors.noAnthropicKey
        }
        return shared
    }
}

extension OpenAICredentials {
    static var sharedOpenRouter: OpenAICredentials? {
        if let key = UserDefaults.standard.string(forKey: DefaultsKeys.openRouterAPIKey.rawValue)?.nilIfEmpty {
            return .init(apiKey: key)
        }
        return nil
    }

    static var sharedOpenAI: OpenAICredentials? {
        if let key = UserDefaults.standard.string(forKey: DefaultsKeys.openAIApiKey.rawValue)?.nilIfEmpty {
            return .init(apiKey: key)
        }
        return nil
    }

    static func getSharedOpenRouterCredsOrThrow() throws -> OpenAICredentials {
        enum Errors: Error {
            case noOpenRouterAPIKey
        }
        guard let sharedOpenRouter else {
            throw Errors.noOpenRouterAPIKey
        }
        return sharedOpenRouter
    }

    static func getSharedOpenAICredsOrThrow() throws -> OpenAICredentials {
        enum Errors: Error {
            case noOpenAIAPIKey
        }
        guard let sharedOpenAI else {
            throw Errors.noOpenAIAPIKey
        }
        return sharedOpenAI
    }
}
